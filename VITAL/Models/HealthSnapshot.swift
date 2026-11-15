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

/// Immutable values captured for a report. The day key is stored at capture time
/// so a later time-zone change cannot move an archived report to another day.
struct DailyReportSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let kind: DailyReportKind
    let localDay: Date
    let localDayKey: String
    let timeZoneIdentifier: String
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
        activeEnergyKcal: Double?,
        calendar: Calendar = .current
    ) {
        self.id = id
        self.kind = kind
        self.localDay = localDay
        self.localDayKey = Self.dayKey(for: localDay, calendar: calendar)
        self.timeZoneIdentifier = calendar.timeZone.identifier
        self.capturedAt = capturedAt
        self.recoveryScore = recoveryScore
        self.bodyBatteryScore = bodyBatteryScore
        self.sleepDurationSeconds = sleepDurationSeconds
        self.hrvMilliseconds = hrvMilliseconds
        self.restingHeartRateBPM = restingHeartRateBPM
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
    }

    /// Backward-compatible decoding for archives created before day keys existed.
    private enum CodingKeys: String, CodingKey {
        case id, kind, localDay, localDayKey, timeZoneIdentifier, capturedAt
        case recoveryScore, bodyBatteryScore, sleepDurationSeconds
        case hrvMilliseconds, restingHeartRateBPM, steps, activeEnergyKcal
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        kind = try values.decode(DailyReportKind.self, forKey: .kind)
        localDay = try values.decode(Date.self, forKey: .localDay)
        capturedAt = try values.decode(Date.self, forKey: .capturedAt)
        recoveryScore = try values.decodeIfPresent(Int.self, forKey: .recoveryScore)
        bodyBatteryScore = try values.decodeIfPresent(Int.self, forKey: .bodyBatteryScore)
        sleepDurationSeconds = try values.decodeIfPresent(TimeInterval.self, forKey: .sleepDurationSeconds)
        hrvMilliseconds = try values.decodeIfPresent(Double.self, forKey: .hrvMilliseconds)
        restingHeartRateBPM = try values.decodeIfPresent(Double.self, forKey: .restingHeartRateBPM)
        steps = try values.decodeIfPresent(Double.self, forKey: .steps)
        activeEnergyKcal = try values.decodeIfPresent(Double.self, forKey: .activeEnergyKcal)
        timeZoneIdentifier = try values.decodeIfPresent(String.self, forKey: .timeZoneIdentifier) ?? "UTC"
        localDayKey = try values.decodeIfPresent(String.self, forKey: .localDayKey)
            ?? Self.dayKey(for: localDay, timeZone: TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(secondsFromGMT: 0)!)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(kind, forKey: .kind)
        try values.encode(localDay, forKey: .localDay)
        try values.encode(localDayKey, forKey: .localDayKey)
        try values.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
        try values.encode(capturedAt, forKey: .capturedAt)
        try values.encodeIfPresent(recoveryScore, forKey: .recoveryScore)
        try values.encodeIfPresent(bodyBatteryScore, forKey: .bodyBatteryScore)
        try values.encodeIfPresent(sleepDurationSeconds, forKey: .sleepDurationSeconds)
        try values.encodeIfPresent(hrvMilliseconds, forKey: .hrvMilliseconds)
        try values.encodeIfPresent(restingHeartRateBPM, forKey: .restingHeartRateBPM)
        try values.encodeIfPresent(steps, forKey: .steps)
        try values.encodeIfPresent(activeEnergyKcal, forKey: .activeEnergyKcal)
    }

    var localDayDisplayText: String {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: localDayKey) else { return localDayKey }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    static func dayKeyForLookup(_ date: Date, calendar: Calendar) -> String {
        dayKey(for: date, timeZone: calendar.timeZone)
    }

    private static func dayKey(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
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
            guard $0.kind == candidate.kind else { return false }
            if !$0.localDayKey.isEmpty && !$0.localDayKey.hasPrefix("0000") {
                return $0.localDayKey == candidate.localDayKey
            }
            return calendar.isDate($0.localDay, inSameDayAs: candidate.localDay)
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
        let key = DailyReportSnapshot.dayKeyForLookup(date, calendar: calendar)
        return snapshots.first {
            $0.kind == kind && (
                $0.localDayKey == key ||
                ($0.localDayKey.isEmpty && calendar.isDate($0.localDay, inSameDayAs: date))
            )
        }
    }
}
