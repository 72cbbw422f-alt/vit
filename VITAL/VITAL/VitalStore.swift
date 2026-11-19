import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
final class VitalStore: ObservableObject {
    @Published var weights: [WeightEntry] { didSet { save(weights, key: "weights") } }
    @Published var workouts: [WorkoutEntry] { didSet { save(workouts, key: "workouts") } }
    @Published var bloodPressures: [BloodPressureEntry] { didSet { save(bloodPressures, key: "bloodPressures") } }
    @Published var goalWeight: Double { didSet { UserDefaults.standard.set(goalWeight, forKey: "vital.goalWeight") } }
    @Published var reports: [VitalDailyReport] { didSet { save(reports, key: "reports") } }
    @Published var moodEntries: [MoodEntry] { didSet { save(moodEntries, key: "moods") } }

    init() {
        weights = Self.load("weights")
        workouts = Self.load("workouts")
        bloodPressures = Self.load("bloodPressures")
        reports = Self.load("reports")
        moodEntries = Self.load("moods")
        goalWeight = UserDefaults.standard.object(forKey: "vital.goalWeight") as? Double ?? 90
    }

    var latestWeight: Double? { weights.sorted { $0.date > $1.date }.first?.kilograms }

    func addWeight(_ kg: Double) { weights.append(WeightEntry(kilograms: kg)) }
    func addWorkout(name: String, duration: Int, notes: String) { workouts.append(WorkoutEntry(name: name, duration: duration, notes: notes)) }
    func addBloodPressure(systolic: Int, diastolic: Int, pulse: Int) {
        bloodPressures.append(BloodPressureEntry(systolic: systolic, diastolic: diastolic, pulse: pulse))
    }

    func saveMood(moods: [String], note: String) {
        moodEntries.removeAll { Calendar.current.isDateInToday($0.date) }
        moodEntries.append(MoodEntry(moods: moods, note: note))
    }

    var todayMood: MoodEntry? { moodEntries.first { Calendar.current.isDateInToday($0.date) } }

    func saveReport(_ report: VitalDailyReport) {
        // Reports are immutable snapshots: never overwrite an existing report of the same type/day.
        let alreadySaved = reports.contains {
            Calendar.current.isDate($0.date, inSameDayAs: report.date) && $0.kind == report.kind
        }
        guard !alreadySaved else { return }
        reports.append(report)
        reports.sort { $0.date > $1.date }
    }

    func report(for kind: VitalReportKind, on date: Date = .now) -> VitalDailyReport? {
        reports.first { $0.kind == kind && Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    @discardableResult
    func captureReportIfNeeded(_ kind: VitalReportKind, health: HealthStore, source: String) -> VitalDailyReport {
        if let existing = report(for: kind) { return existing }
        let bp = health.systolic != nil && health.diastolic != nil ? "\(Int(health.systolic!))/\(Int(health.diastolic!)) mmHg" : nil
        let summary: String
        if health.readinessTitle == "Inväntar hälsodata" {
            summary = "VITAL saknar tillräckligt med hälsodata för en samlad bedömning. Kontrollera behörigheterna i Apple Hälsa."
        } else {
            summary = "\(health.readinessTitle). Analysen bygger på tillgängliga värden och din personliga historik."
        }
        let item = VitalDailyReport(date: Date(), kind: kind, readiness: health.recoveryScore,
            bodyBattery: health.bodyBattery, sleepHours: health.sleepHours,
            restingHeartRate: health.restingHeartRate, hrv: health.hrv, steps: health.steps,
            respiratoryRate: health.respiratoryRate, activeEnergy: health.activeEnergy,
            bloodPressure: bp, summary: summary, recommendation: health.readinessAdvice,
            stressScore: health.stressScore, heartRate: health.heartRate,
            wristTemperature: health.wristTemperature, exerciseMinutes: health.exerciseMinutes,
            captureSource: source)
        saveReport(item)
        return report(for: kind) ?? item
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: "vital.data.\(key)")
    }

    private static func load<T: Decodable>(_ key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: "vital.data.\(key)"),
              let value = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return value
    }
}

@MainActor
final class VitalNotifications: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    @Published var status = "Kontrollerar notisbehörighet…"
    @Published var morningEnabled = UserDefaults.standard.object(forKey: "vital.notice.morning") as? Bool ?? true
    @Published var eveningEnabled = UserDefaults.standard.object(forKey: "vital.notice.evening") as? Bool ?? true
    @Published var bpDailyEnabled = UserDefaults.standard.object(forKey: "vital.notice.bpDaily") as? Bool ?? true
    @Published var weightReminderEnabled = UserDefaults.standard.object(forKey: "vital.notice.weightWeekly") as? Bool ?? false
    @Published var weightReminderWeekday = UserDefaults.standard.object(forKey: "vital.notice.weightWeekday") as? Int ?? 2
    @Published private(set) var weightReminderHour = UserDefaults.standard.object(forKey: "vital.notice.weightHour") as? Int ?? 9
    @Published private(set) var weightReminderMinute = UserDefaults.standard.object(forKey: "vital.notice.weightMinute") as? Int ?? 0
    var weightReminderTime: Date {
        Calendar.current.date(from: DateComponents(hour: weightReminderHour, minute: weightReminderMinute)) ?? .now
    }
    @Published var reportToOpen: VitalReportKind?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if let raw = info["reportKind"] as? String, let kind = VitalReportKind(rawValue: raw) {
            Task { @MainActor in self.reportToOpen = kind }
        }
        completionHandler()
    }

    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                self?.status = self?.isAuthorized == true ? "Notiser är tillåtna på den här enheten." : "Notiser är inte aktiverade."
            }
        }
    }

    func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthorized = granted
                if granted {
                    self.scheduleAll()
                    self.status = "Notiser är aktiverade. Välj vilka påminnelser du vill ha."
                } else {
                    self.status = error?.localizedDescription ?? "Notiser nekades. Aktivera dem i iPhone-inställningarna."
                }
            }
        }
    }

    func setMorning(_ value: Bool) { morningEnabled = value; UserDefaults.standard.set(value, forKey: "vital.notice.morning"); updateSchedule() }
    func setEvening(_ value: Bool) { eveningEnabled = value; UserDefaults.standard.set(value, forKey: "vital.notice.evening"); updateSchedule() }
    func setBPDaily(_ value: Bool) { bpDailyEnabled = value; UserDefaults.standard.set(value, forKey: "vital.notice.bpDaily"); updateSchedule() }
    func setWeightReminderEnabled(_ value: Bool) {
        weightReminderEnabled = value
        UserDefaults.standard.set(value, forKey: "vital.notice.weightWeekly")
        updateSchedule()
    }
    func setWeightReminderWeekday(_ value: Int) {
        weightReminderWeekday = min(max(value, 1), 7)
        UserDefaults.standard.set(weightReminderWeekday, forKey: "vital.notice.weightWeekday")
        updateSchedule()
    }
    func setWeightReminderTime(_ date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        weightReminderHour = parts.hour ?? 9
        weightReminderMinute = parts.minute ?? 0
        UserDefaults.standard.set(weightReminderHour, forKey: "vital.notice.weightHour")
        UserDefaults.standard.set(weightReminderMinute, forKey: "vital.notice.weightMinute")
        updateSchedule()
    }

    func scheduleAll() {
        let center = UNUserNotificationCenter.current()
        let ids = ["vital.morning", "vital.evening", "vital.bp.daily", "vital.bp.morning", "vital.bp.evening", "vital.weight.weekly"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        if morningEnabled { schedule(id: "vital.morning", title: "Din morgonrapport är redo", body: "Öppna VITAL för dagens återhämtning, sömn och personliga rekommendation.", hour: 8, minute: 0, report: .morning) }
        if eveningEnabled { schedule(id: "vital.evening", title: "Din kvällsrapport är redo", body: "Summera dagens aktivitet och se kroppens signaler inför natten.", hour: 21, minute: 0, report: .evening) }
        if bpDailyEnabled { schedule(id: "vital.bp.daily", title: "Dags för blodtryck", body: "Dags för dagens blodtrycksmätning. VITAL hämtar resultatet automatiskt från Apple Hälsa när det synkroniserats.", hour: 18, minute: 0) }
        if weightReminderEnabled {
            schedule(id: "vital.weight.weekly", title: "Dags att väga dig", body: "Registrera veckans vikt i VITAL och följ din utveckling över tid.", hour: weightReminderHour, minute: weightReminderMinute, weekday: weightReminderWeekday)
        }
    }

    private func updateSchedule() { if isAuthorized { scheduleAll() } }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int, report: VitalReportKind? = nil, weekday: Int? = nil) {
        var components = DateComponents(); components.hour = hour; components.minute = minute; components.weekday = weekday
        let content = UNMutableNotificationContent(); content.title = title; content.body = body; content.sound = .default
        if let report { content.userInfo = ["reportKind": report.rawValue] }
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
