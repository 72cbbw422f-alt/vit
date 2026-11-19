import Foundation
import HealthKit
import Combine

@MainActor
final class HealthStore: ObservableObject {
    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var isRefreshing = false
    @Published var steps: Double?
    @Published var heartRate: Double?
    @Published var heartRateSampleDate: Date?
    @Published var recentHeartRateSamples: [VitalTrendPoint] = []
    @Published var stressScore: Int?
    @Published var restingHeartRateBaseline60d: Double?
    @Published var restingHeartRate: Double?
    @Published var hrv: Double?
    @Published var hrvBaseline7d: Double?
    @Published var hrvBaseline30d: Double?
    @Published var hrvHistory: [VitalTrendPoint] = []
    @Published var restingPulseHistory: [VitalTrendPoint] = []
    @Published var weightHistory: [VitalTrendPoint] = []
    @Published var systolicHistory: [VitalTrendPoint] = []
    @Published var diastolicHistory: [VitalTrendPoint] = []
    @Published var bloodPressureHistory: [BloodPressureTrendPoint] = []
    @Published var restingHeartRateBaseline7d: Double?
    @Published var restingHeartRateBaseline30d: Double?
    @Published var sleepHours: Double?
    @Published var respiratoryRate: Double?
    @Published var wristTemperature: Double?
    @Published var bodyMass: Double?
    @Published var systolic: Double?
    @Published var diastolic: Double?
    @Published var activeEnergy: Double?
    @Published var exerciseMinutes: Double?
    @Published var lastUpdated: Date?
    @Published var statusMessage = "Anslut Apple Hälsa för att läsa dina hälsodata."

    private let store = HKHealthStore()

    func requestAccess() {
        guard isAvailable else {
            statusMessage = "Apple Hälsa är inte tillgängligt på den här enheten."
            return
        }
        let identifiers: [HKObjectType?] = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
            HKObjectType.correlationType(forIdentifier: .bloodPressure),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)
        ]
        let readTypes = Set(identifiers.compactMap { $0 })
        statusMessage = "Begär hälsobehörighet…"
        store.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthorized = success
                if let error {
                    self.statusMessage = "Kunde inte begära behörighet: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Förfrågan skickad. Kontrollera åtkomsten i appen Hälsa om värden saknas."
                }
                self.refresh()
            }
        }
    }

    func refresh() {
        guard isAvailable else {
            statusMessage = "Apple Hälsa är inte tillgängligt."
            return
        }
        isRefreshing = true
        fetchSteps()
        fetchLatestHeartRate()
        fetchRecentHeartRates()
        fetchBaseline(.restingHeartRate, days: 60, unit: HKUnit.count().unitDivided(by: .minute())) { self.restingHeartRateBaseline60d = $0; self.updateStressEstimate() }
        fetchLatest(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) { self.restingHeartRate = $0 }
        fetchLatest(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { self.hrv = $0 }
        fetchBaseline(.heartRateVariabilitySDNN, days: 7, unit: .secondUnit(with: .milli)) { self.hrvBaseline7d = $0 }
        fetchBaseline(.heartRateVariabilitySDNN, days: 30, unit: .secondUnit(with: .milli)) { self.hrvBaseline30d = $0 }
        fetchTrend(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { self.hrvHistory = $0 }
        fetchTrend(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) { self.restingPulseHistory = $0 }
        fetchLongTrend(.bodyMass, unit: .gramUnit(with: .kilo)) { self.weightHistory = $0 }
        fetchLongTrend(.bloodPressureSystolic, unit: .millimeterOfMercury()) { self.systolicHistory = $0 }
        fetchLongTrend(.bloodPressureDiastolic, unit: .millimeterOfMercury()) { self.diastolicHistory = $0 }
        fetchBloodPressureHistory()
        fetchBaseline(.restingHeartRate, days: 7, unit: HKUnit.count().unitDivided(by: .minute())) { self.restingHeartRateBaseline7d = $0 }
        fetchBaseline(.restingHeartRate, days: 30, unit: HKUnit.count().unitDivided(by: .minute())) { self.restingHeartRateBaseline30d = $0 }
        fetchLatest(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute())) { self.respiratoryRate = $0 }
        fetchLatest(.appleSleepingWristTemperature, unit: .degreeCelsius()) { self.wristTemperature = $0 }
        fetchLatest(.bodyMass, unit: .gramUnit(with: .kilo)) { self.bodyMass = $0 }
        fetchLatest(.bloodPressureSystolic, unit: .millimeterOfMercury()) { self.systolic = $0 }
        fetchLatest(.bloodPressureDiastolic, unit: .millimeterOfMercury()) { self.diastolic = $0 }
        fetchToday(.activeEnergyBurned, unit: .kilocalorie()) { self.activeEnergy = $0 }
        fetchToday(.appleExerciseTime, unit: .minute()) { self.exerciseMinutes = $0 }
        fetchSleep()
        lastUpdated = Date()
    }

    private func fetchSteps() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            steps = nil
            isRefreshing = false
            statusMessage = "Stegdata stöds inte på den här enheten."
            return
        }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            let value = result?.sumQuantity()?.doubleValue(for: .count())
            Task { @MainActor in
                guard let self else { return }
                self.steps = value
                self.isRefreshing = false
                if let error {
                    self.statusMessage = "Kunde inte läsa steg: \(error.localizedDescription)"
                } else if let value {
                    self.statusMessage = "Apple Hälsa uppdaterad · \(Int(value).formatted()) steg idag."
                } else {
                    self.statusMessage = "Ingen stegdata hittades idag. Kontrollera att VITAL får läsa Steg i appen Hälsa."
                }
            }
        }
        store.execute(query)
    }

    private func fetchLatestHeartRate() {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let sample = samples?.first as? HKQuantitySample
            let value = sample?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let date = sample?.endDate
            Task { @MainActor in
                guard let self else { return }
                self.heartRate = value
                self.heartRateSampleDate = date
                self.updateStressEstimate()
            }
        }
        store.execute(query)
    }

    private func fetchRecentHeartRates() {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -2, to: end) ?? end.addingTimeInterval(-7200)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 500, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let points = (samples as? [HKQuantitySample] ?? []).map {
                VitalTrendPoint(date: $0.endDate, value: $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            Task { @MainActor in
                guard let self else { return }
                self.recentHeartRateSamples = points
                self.updateStressEstimate()
            }
        }
        store.execute(query)
    }

    private func updateStressEstimate() {
        guard let baseline = restingHeartRateBaseline60d, baseline > 0,
              recentHeartRateSamples.count >= 3,
              let newest = recentHeartRateSamples.last,
              Date().timeIntervalSince(newest.date) <= 60 * 60 else {
            stressScore = nil
            return
        }
        // Use the recent two-hour average rather than one isolated pulse sample.
        let averageHR = recentHeartRateSamples.map(\.value).reduce(0, +) / Double(recentHeartRateSamples.count)
        let pulseLoad = min(max((averageHR - baseline - 3) * 2.5, 0), 70)
        // HRV below the personal 30-day baseline adds a modest secondary signal.
        let hrvLoad: Double
        if let hrv, let hrvBaseline30d, hrvBaseline30d > 0 {
            let deviation = max((hrvBaseline30d - hrv) / hrvBaseline30d, 0)
            hrvLoad = min(deviation * 45, 30)
        } else {
            hrvLoad = 0
        }
        stressScore = Int(min(max(5 + pulseLoad + hrvLoad, 5), 100).rounded())
    }

    private var recentHeartRateAverage: Double? {
        guard recentHeartRateSamples.count >= 4 else { return nil }
        return recentHeartRateSamples.map(\.value).reduce(0, +) / Double(recentHeartRateSamples.count)
    }

    // Rest is allowed to recharge the battery when pulse remains close to
    // the user's baseline. HRV-derived stress alone must not block recovery.
    var daytimeRecoveryCredit: Double {
        guard let baseline = restingHeartRateBaseline60d, baseline > 0,
              let averageHR = recentHeartRateAverage,
              let first = recentHeartRateSamples.first?.date,
              let last = recentHeartRateSamples.last?.date else { return 0 }
        let coveredHours = last.timeIntervalSince(first) / 3600
        guard coveredHours >= 0.75, averageHR <= baseline + 5 else { return 0 }
        return min(coveredHours * 2.0, 8)
    }

    var stressStatus: String {
        guard let stressScore else { return "Inväntar aktuell puls och baslinje" }
        if stressScore < 25 { return "Låg fysiologisk belastning" }
        if stressScore < 60 { return "Måttlig fysiologisk belastning" }
        return "Hög fysiologisk belastning"
    }

    var stressDataDescription: String {
        guard let sampleDate = heartRateSampleDate, stressScore != nil else { return "Saknar aktuell puls eller personlig baslinje." }
        return "Medel av \(recentHeartRateSamples.count) pulsmätningar senaste 2 h · jämfört med 60-dagars vilopuls och HRV-baslinje · senast " + sampleDate.formatted(date: .omitted, time: .shortened)
    }

    private func fetchLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping @MainActor (Double?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
            Task { @MainActor in completion(value) }
        }
        store.execute(query)
    }

    private func fetchToday(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping @MainActor (Double?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: unit)
            Task { @MainActor in completion(value) }
        }
        store.execute(query)
    }

    private func fetchSleep() {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]
            let seconds = (samples as? [HKCategorySample] ?? [])
                .filter { asleepValues.contains($0.value) }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            Task { @MainActor in self?.sleepHours = seconds > 0 ? seconds / 3600 : nil }
        }
        store.execute(query)
    }


    private func fetchBaseline(_ identifier: HKQuantityTypeIdentifier, days: Int = 30, unit: HKUnit, completion: @escaping @MainActor (Double?) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, samples, _ in
            let values = (samples as? [HKQuantitySample] ?? []).map { $0.quantity.doubleValue(for: unit) }
            let average = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
            Task { @MainActor in completion(average) }
        }
        store.execute(query)
    }

    private func fetchTrend(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping @MainActor ([VitalTrendPoint]) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 500, sortDescriptors: [sort]) { _, samples, _ in
            let points = (samples as? [HKQuantitySample] ?? []).map {
                VitalTrendPoint(date: $0.endDate, value: $0.quantity.doubleValue(for: unit))
            }
            Task { @MainActor in completion(points) }
        }
        store.execute(query)
    }

    private func fetchLongTrend(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping @MainActor ([VitalTrendPoint]) -> Void) {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 2000, sortDescriptors: [sort]) { _, samples, _ in
            let points = (samples as? [HKQuantitySample] ?? []).map {
                VitalTrendPoint(date: $0.endDate, value: $0.quantity.doubleValue(for: unit))
            }
            Task { @MainActor in completion(points) }
        }
        store.execute(query)
    }

    // Read blood pressure as HealthKit correlations so systolic and diastolic
    // values stay paired with the same measurement timestamp.
    private func fetchBloodPressureHistory() {
        guard let correlationType = HKObjectType.correlationType(forIdentifier: .bloodPressure),
              let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        let start = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: correlationType, predicate: predicate, limit: 2000, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let points: [BloodPressureTrendPoint] = (samples as? [HKCorrelation] ?? []).compactMap { correlation in
                guard let sys = correlation.objects(for: systolicType).first as? HKQuantitySample,
                      let dia = correlation.objects(for: diastolicType).first as? HKQuantitySample else { return nil }
                return BloodPressureTrendPoint(
                    date: correlation.endDate,
                    systolic: sys.quantity.doubleValue(for: .millimeterOfMercury()),
                    diastolic: dia.quantity.doubleValue(for: .millimeterOfMercury())
                )
            }
            Task { @MainActor in self?.bloodPressureHistory = points }
        }
        store.execute(query)
    }

    var hrvBaselineDescription: String {
        guard let current = hrv, let baseline = hrvBaseline30d, baseline > 0 else {
            return "Otillräckligt underlag för personlig jämförelse"
        }
        let difference = current - baseline
        let percent = Int((difference / baseline * 100).rounded())
        let sign = percent > 0 ? "+" : ""
        return "30-dagars snitt \(Int(baseline)) ms · \(sign)\(percent)% mot din baslinje"
    }

    var restingPulseIsElevated: Bool {
        guard let current = restingHeartRate, let baseline = restingHeartRateBaseline30d else { return false }
        return current > baseline + 5
    }

    var restingPulseComparison: String {
        guard let current = restingHeartRate, let baseline = restingHeartRateBaseline30d else { return "Baslinje byggs" }
        let difference = current - baseline
        if difference > 3 { return "Över ditt snitt" }
        if difference < -3 { return "Under ditt snitt" }
        return "Nära ditt snitt"
    }

    var hrvStatus: String {
        guard let current = hrv, let baseline = hrvBaseline30d, baseline > 0 else { return "Bygger personlig baslinje" }
        let change = (current - baseline) / baseline
        if change >= 0.08 { return "Över din baslinje" }
        if change <= -0.08 { return "Under din baslinje" }
        return "Nära din baslinje"
    }

    var readinessTitle: String {
        guard hrv != nil || restingHeartRate != nil || sleepHours != nil else { return "Inväntar hälsodata" }
        if let sleepHours, sleepHours < 6 { return "Du har sovit kort" }
        guard hrvBaseline30d != nil || restingHeartRateBaseline30d != nil else { return "Bygger din baslinje" }
        if let hrv, let base = hrvBaseline30d, hrv < base * 0.88 { return "Ta det lite lugnare" }
        if let pulse = restingHeartRate, let base = restingHeartRateBaseline30d, pulse > base + 5 { return "Prioritera återhämtning" }
        return "Signalerna ser stabila ut"
    }

    var readinessAdvice: String {
        switch readinessTitle {
        case "Inväntar hälsodata": return "Anslut Apple Hälsa och samla mätningar för att få en dagsbedömning."
        case "Bygger din baslinje": return "VITAL samlar data för att lära känna dina normala HRV- och vilopulsvärden."
        case "Ta det lite lugnare": return "HRV ligger tydligt under din personliga nivå. Överväg ett lättare pass och följ hur du känner dig."
        case "Prioritera återhämtning": return "Vilopulsen ligger över din personliga nivå. Välj gärna lugnare aktivitet och följ dagsformen."
        case "Du har sovit kort": return "Sömnen var kort. Anpassa träningsintensiteten efter hur du känner dig idag."
        default: return "Tillgängliga signaler är relativt stabila. Träna efter plan om du känner dig frisk och pigg."
        }
    }

    // Transparent component contributions used by the overnight recovery card.
    // These are point adjustments from a neutral starting value of 100.
    var recoverySleepContribution: Double? {
        guard let sleepHours else { return nil }
        return min(max((sleepHours - 7.0) * 7.0, -28), 14)
    }

    var recoveryHRVContribution: Double? {
        guard let hrv, let baseline = hrvBaseline30d, baseline > 0 else { return nil }
        let deviation = (hrv - baseline) / baseline
        return min(max(deviation * 55.0, -18), 12)
    }

    var recoveryPulseContribution: Double? {
        guard let pulse = restingHeartRate, let baseline = restingHeartRateBaseline30d, baseline > 0 else { return nil }
        return min(max((baseline - pulse) * 2.0, -12), 8)
    }

    var recoveryEvidenceCount: Int {
        [recoverySleepContribution, recoveryHRVContribution, recoveryPulseContribution].compactMap { $0 }.count
    }

    var recoveryScoreExplanation: String {
        recoveryEvidenceCount == 3
            ? "Alla tre återhämtningssignalerna finns tillgängliga."
            : "Poängen bygger på \(recoveryEvidenceCount) av 3 signaler. Saknade mätvärden räknas inte som noll."
    }
    // Overnight recovery is a morning-oriented estimate. It uses sleep and
    // personal HRV/resting-pulse deviations; it is not a medical measurement.
    var recoveryScore: Int? {
        guard sleepHours != nil || hrv != nil || restingHeartRate != nil else { return nil }
        var score = 100.0
        var evidence = 0
        if let contribution = recoverySleepContribution { score += contribution; evidence += 1 }
        if let contribution = recoveryHRVContribution { score += contribution; evidence += 1 }
        if let contribution = recoveryPulseContribution { score += contribution; evidence += 1 }
        // Avoid presenting a precise score when only one weak signal exists.
        guard evidence >= 2 else { return nil }
        return Int(min(max(score, 0), 100))
    }

    // Dynamic daytime estimate. The overnight score is the starting point;
    // activity/effort reduces the estimate as new HealthKit totals arrive.
    // This is a VITAL estimate, not a directly measured Apple Health metric.
    var bodyBattery: Int? {
        guard let recoveryScore else { return nil }
        // These HealthKit activity totals overlap (a walk can add steps,
        // active energy and exercise minutes). Use the strongest signal as
        // the main load and only a small corroborating adjustment from the
        // other signals, so one activity is not counted three times.
        let energyLoad = min((activeEnergy ?? 0) / 45.0, 24)
        let exerciseLoad = min(Double(exerciseMinutes ?? 0) / 4.0, 18)
        let stepLoad = min((steps ?? 0) / 2500.0, 18)
        let loads = [energyLoad, exerciseLoad, stepLoad].sorted(by: >)
        let primaryLoad = loads[0]
        let supportingLoad = (loads.count > 1 ? loads[1] * 0.15 : 0)
            + (loads.count > 2 ? loads[2] * 0.05 : 0)
        let totalLoad = min(primaryLoad + supportingLoad, 28)
        // Only elevated recent pulse drains the battery as ongoing physiological
        // load. HRV can raise the stress indicator, but by itself should not
        // drain energy while the user is resting with a near-baseline pulse.
        let pulseLoad: Double
        if let averageHR = recentHeartRateAverage, let baseline = restingHeartRateBaseline60d {
            pulseLoad = min(max((averageHR - baseline - 5) * 0.35, 0), 6)
        } else {
            pulseLoad = 0
        }
        let recoveryCredit = daytimeRecoveryCredit
        return Int(min(max(Double(recoveryScore) - totalLoad - pulseLoad + recoveryCredit, 0), 100))
    }

    var recoveryStatus: String {
        guard let score = recoveryScore else { return "Otillräckligt underlag" }
        if score >= 80 { return "God nattlig återhämtning" }
        if score >= 60 { return "Måttlig nattlig återhämtning" }
        return "Låg nattlig återhämtning"
    }

    var bodyBatteryStatus: String {
        guard let value = bodyBattery else { return "Inväntar hälsodata" }
        if value >= 75 { return "Gott om uppskattad energi" }
        if value >= 45 { return "Måttlig energinivå" }
        return "Låg uppskattad energinivå"
    }
}
