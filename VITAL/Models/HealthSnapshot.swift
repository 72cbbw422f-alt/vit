import Foundation

struct HealthSnapshot {
    var sleepDuration: TimeInterval?
    var restingHeartRate: Double?
    var hrv: Double?
    var overnightHRV: Double?
    var overnightRestingHeartRate: Double?
    var steps: Double?
    var activeEnergy: Double?
    var latestWeight: Double?
    var restingHeartRateBaseline: PersonalBaseline?
    var hrvBaseline: PersonalBaseline?
    var sleepBaseline: PersonalBaseline?
    var lastUpdated: Date?
    var bodyBattery: BodyBatteryResult?

    static let empty = HealthSnapshot()

    /// Uses the weakest of the three baseline day counts; one metric cannot
    /// make the overall baseline appear ready when another is incomplete.
    var recoveryResult: RecoveryResult {
        let availableDays = min(
            restingHeartRateBaseline?.validDays ?? 0,
            hrvBaseline?.validDays ?? 0,
            sleepBaseline?.validDays ?? 0
        )
        return RecoveryEngine.calculate(RecoveryInputs(
            sleepDurationHours: sleepDuration.map { $0 / 3600 },
            baselineSleepHours: sleepBaseline?.median,
            hrvMilliseconds: overnightHRV,
            baselineHRVMilliseconds: hrvBaseline?.median,
            restingHeartRateBPM: overnightRestingHeartRate,
            baselineRestingHeartRateBPM: restingHeartRateBaseline?.median,
            baselineDaysAvailable: availableDays
        ))
    }

    var sleepText: String {
        guard let sleepDuration else { return "—" }
        let hours = Int(sleepDuration) / 3600
        let minutes = (Int(sleepDuration) % 3600) / 60
        return "\(hours) h \(String(format: "%02d", minutes)) min"
    }
    var stepsText: String {
        guard let steps else { return "—" }
        return Int(steps).formatted()
    }
    var restingHeartRateText: String {
        guard let restingHeartRate else { return "—" }
        return "\(Int(restingHeartRate.rounded())) bpm"
    }
    var hrvText: String {
        guard let hrv else { return "—" }
        return "\(Int(hrv.rounded())) ms"
    }
}


enum DailyReportKind: String, Codable {
    case morning
    case evening
}

/// Immutable values captured for a report. Later HealthKit updates must never
/// mutate an already-created report for the same local day and report kind.
struct DailyReportSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let kind: DailyReportKind
    let localDay: Date
    let capturedAt: Date
    let recoveryScore: Int?
    let bodyBatteryScore: Int?
    let sleepDurationSeconds: TimeInterval?
    let hrvMilliseconds: Double?
    let restingHeartRateBPM: Double?
    let steps: Double?
    let activeEnergyKcal: Double?

    init(
        id: UUID = UUID(),
        kind: DailyReportKind,
        localDay: Date,
        capturedAt: Date,
        recoveryScore: Int?,
        bodyBatteryScore: Int?,
        sleepDurationSeconds: TimeInterval?,
        hrvMilliseconds: Double?,
        restingHeartRateBPM: Double?,
        steps: Double?,
        activeEnergyKcal: Double?
    ) {
        self.id = id
        self.kind = kind
        self.localDay = localDay
        self.capturedAt = capturedAt
        self.recoveryScore = recoveryScore
        self.bodyBatteryScore = bodyBatteryScore
        self.sleepDurationSeconds = sleepDurationSeconds
        self.hrvMilliseconds = hrvMilliseconds
        self.restingHeartRateBPM = restingHeartRateBPM
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
    }
}

/// Small deterministic archive policy. Persistence is deliberately kept out of
/// the core model so the same rules can be tested without UserDefaults/HealthKit.
struct ReportSnapshotArchive: Codable, Equatable {
    private(set) var snapshots: [DailyReportSnapshot] = []

    @discardableResult
    mutating func appendIfAbsent(
        _ candidate: DailyReportSnapshot,
        calendar: Calendar = .current
    ) -> Bool {
        let alreadyExists = snapshots.contains {
            $0.kind == candidate.kind && calendar.isDate($0.localDay, inSameDayAs: candidate.localDay)
        }
        guard !alreadyExists else { return false }
        snapshots.append(candidate)
        snapshots.sort { $0.capturedAt < $1.capturedAt }
        return true
    }

    func snapshot(
        for date: Date,
        kind: DailyReportKind,
        calendar: Calendar = .current
    ) -> DailyReportSnapshot? {
        snapshots.first {
            $0.kind == kind && calendar.isDate($0.localDay, inSameDayAs: date)
        }
    }
}
