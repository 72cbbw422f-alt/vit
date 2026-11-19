import Foundation

enum BloodPressureReadingValidator {
    /// Defensive data-quality bounds for imported HealthKit pairs, not clinical thresholds.
    static func isValid(systolic: Double, diastolic: Double) -> Bool {
        systolic.isFinite && diastolic.isFinite &&
        (60...260).contains(systolic) &&
        (30...160).contains(diastolic) &&
        systolic > diastolic
    }
}

struct HealthSnapshot {
    var sleepDuration: TimeInterval?
    var restingHeartRate: Double?
    var hrv: Double?
    var overnightHRV: Double?
    var overnightRestingHeartRate: Double?
    var steps: Double?
    var activeEnergy: Double?
    var latestWeight: Double?
    var latestWeightDate: Date?
    var systolicBloodPressure: Double?
    var diastolicBloodPressure: Double?
    var bloodPressureDate: Date?
    /// Latest HealthKit respiratory rate in breaths per minute.
    var respiratoryRate: Double?
    var respiratoryRateDate: Date?
    /// Apple Watch sleeping wrist temperature is a deviation from baseline, not core body temperature.
    var sleepingWristTemperatureDeviationCelsius: Double?
    var sleepingWristTemperatureDate: Date?
    var exerciseMinutes: Double?
    var walkingRunningDistanceKM: Double?
    var cyclingDistanceKM: Double?
    var flightsClimbed: Double?
    var walkingHeartRate: Double?
    var walkingHeartRateDate: Date?
    var vo2Max: Double?
    var vo2MaxDate: Date?
    var bodyFatPercentage: Double?
    var bodyFatDate: Date?
    var leanBodyMassKG: Double?
    var leanBodyMassDate: Date?
    var walkingSpeedMetersPerSecond: Double?
    var walkingSpeedDate: Date?
    var walkingStepLengthCM: Double?
    var walkingStepLengthDate: Date?
    var walkingAsymmetryPercentage: Double?
    var walkingAsymmetryDate: Date?
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
        guard let sleepDuration, sleepDuration.isFinite, sleepDuration >= 1800, sleepDuration <= 24 * 3600 else { return "—" }
        let hours = Int(sleepDuration) / 3600
        let minutes = (Int(sleepDuration) % 3600) / 60
        return "\(hours) h \(String(format: "%02d", minutes)) min"
    }
    var stepsText: String {
        guard let steps, steps.isFinite, steps >= 0, steps <= 200_000 else { return "—" }
        return Int(steps).formatted()
    }
    var restingHeartRateText: String {
        guard let restingHeartRate, restingHeartRate.isFinite, (25...220).contains(restingHeartRate) else { return "—" }
        return "\(Int(restingHeartRate.rounded())) bpm"
    }
    var hrvText: String {
        guard let hrv, hrv.isFinite, (1...300).contains(hrv) else { return "—" }
        return "\(Int(hrv.rounded())) ms"
    }
    var bloodPressureText: String {
        guard let systolicBloodPressure, let diastolicBloodPressure,
              BloodPressureReadingValidator.isValid(systolic: systolicBloodPressure, diastolic: diastolicBloodPressure) else { return "—" }
        return "\(Int(systolicBloodPressure.rounded()))/\(Int(diastolicBloodPressure.rounded()))"
    }
    var respiratoryRateText: String {
        guard let respiratoryRate, respiratoryRate.isFinite,
              (1...100).contains(respiratoryRate) else { return "—" }
        return "\(Int(respiratoryRate.rounded())) andetag/min"
    }
    var sleepingWristTemperatureText: String {
        guard let sleepingWristTemperatureDeviationCelsius,
              sleepingWristTemperatureDeviationCelsius.isFinite,
              (-5...5).contains(sleepingWristTemperatureDeviationCelsius) else { return "—" }
        let sign = sleepingWristTemperatureDeviationCelsius > 0 ? "+" : ""
        return sign + sleepingWristTemperatureDeviationCelsius.formatted(.number.precision(.fractionLength(2))) + " °C"
    }
    var exerciseMinutesText: String {
        guard let exerciseMinutes, exerciseMinutes.isFinite, (0...1440).contains(exerciseMinutes) else { return "—" }
        return "\(Int(exerciseMinutes.rounded())) min"
    }
    var walkingRunningDistanceText: String {
        guard let walkingRunningDistanceKM, walkingRunningDistanceKM.isFinite, (0...500).contains(walkingRunningDistanceKM) else { return "—" }
        return walkingRunningDistanceKM.formatted(.number.precision(.fractionLength(1))) + " km"
    }
    var cyclingDistanceText: String {
        guard let cyclingDistanceKM, cyclingDistanceKM.isFinite, (0...1000).contains(cyclingDistanceKM) else { return "—" }
        return cyclingDistanceKM.formatted(.number.precision(.fractionLength(1))) + " km"
    }
    var flightsClimbedText: String {
        guard let flightsClimbed, flightsClimbed.isFinite, (0...1000).contains(flightsClimbed) else { return "—" }
        return "\(Int(flightsClimbed.rounded())) våningar"
    }
    var walkingHeartRateText: String {
        guard let walkingHeartRate, walkingHeartRate.isFinite, (25...220).contains(walkingHeartRate) else { return "—" }
        return "\(Int(walkingHeartRate.rounded())) bpm"
    }
    var vo2MaxText: String {
        guard let vo2Max, vo2Max.isFinite, (5...100).contains(vo2Max) else { return "—" }
        return vo2Max.formatted(.number.precision(.fractionLength(1))) + " ml/kg/min"
    }
    var bodyFatText: String {
        guard let bodyFatPercentage, bodyFatPercentage.isFinite, (1...70).contains(bodyFatPercentage) else { return "—" }
        return bodyFatPercentage.formatted(.number.precision(.fractionLength(1))) + " %"
    }
    var leanBodyMassText: String {
        guard let leanBodyMassKG, leanBodyMassKG.isFinite, (1...250).contains(leanBodyMassKG) else { return "—" }
        return leanBodyMassKG.formatted(.number.precision(.fractionLength(1))) + " kg"
    }
    var walkingSpeedText: String {
        guard let walkingSpeedMetersPerSecond, walkingSpeedMetersPerSecond.isFinite, (0.1...5).contains(walkingSpeedMetersPerSecond) else { return "—" }
        return walkingSpeedMetersPerSecond.formatted(.number.precision(.fractionLength(2))) + " m/s"
    }
    var walkingStepLengthText: String {
        guard let walkingStepLengthCM, walkingStepLengthCM.isFinite, (10...200).contains(walkingStepLengthCM) else { return "—" }
        return "\(Int(walkingStepLengthCM.rounded())) cm"
    }
    var walkingAsymmetryText: String {
        guard let walkingAsymmetryPercentage, walkingAsymmetryPercentage.isFinite, (0...100).contains(walkingAsymmetryPercentage) else { return "—" }
        return walkingAsymmetryPercentage.formatted(.number.precision(.fractionLength(1))) + " %"
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
    let sleepComponentScore: Double?
    let hrvComponentScore: Double?
    let restingPulseComponentScore: Double?
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
        sleepComponentScore: Double? = nil,
        hrvComponentScore: Double? = nil,
        restingPulseComponentScore: Double? = nil,
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
        self.localDayKey = Self.dayKeyForLookup(localDay, calendar: calendar)
        self.timeZoneIdentifier = calendar.timeZone.identifier
        self.capturedAt = capturedAt
        self.recoveryScore = recoveryScore
        self.sleepComponentScore = sleepComponentScore
        self.hrvComponentScore = hrvComponentScore
        self.restingPulseComponentScore = restingPulseComponentScore
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
        case recoveryScore, sleepComponentScore, hrvComponentScore, restingPulseComponentScore
        case bodyBatteryScore, sleepDurationSeconds
        case hrvMilliseconds, restingHeartRateBPM, steps, activeEnergyKcal
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        kind = try values.decode(DailyReportKind.self, forKey: .kind)
        localDay = try values.decode(Date.self, forKey: .localDay)
        capturedAt = try values.decode(Date.self, forKey: .capturedAt)
        recoveryScore = try values.decodeIfPresent(Int.self, forKey: .recoveryScore)
        sleepComponentScore = try values.decodeIfPresent(Double.self, forKey: .sleepComponentScore)
        hrvComponentScore = try values.decodeIfPresent(Double.self, forKey: .hrvComponentScore)
        restingPulseComponentScore = try values.decodeIfPresent(Double.self, forKey: .restingPulseComponentScore)
        bodyBatteryScore = try values.decodeIfPresent(Int.self, forKey: .bodyBatteryScore)
        sleepDurationSeconds = try values.decodeIfPresent(TimeInterval.self, forKey: .sleepDurationSeconds)
        hrvMilliseconds = try values.decodeIfPresent(Double.self, forKey: .hrvMilliseconds)
        restingHeartRateBPM = try values.decodeIfPresent(Double.self, forKey: .restingHeartRateBPM)
        steps = try values.decodeIfPresent(Double.self, forKey: .steps)
        activeEnergyKcal = try values.decodeIfPresent(Double.self, forKey: .activeEnergyKcal)
        timeZoneIdentifier = try values.decodeIfPresent(String.self, forKey: .timeZoneIdentifier) ?? ""
        localDayKey = try values.decodeIfPresent(String.self, forKey: .localDayKey) ?? ""
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
        try values.encodeIfPresent(sleepComponentScore, forKey: .sleepComponentScore)
        try values.encodeIfPresent(hrvComponentScore, forKey: .hrvComponentScore)
        try values.encodeIfPresent(restingPulseComponentScore, forKey: .restingPulseComponentScore)
        try values.encodeIfPresent(bodyBatteryScore, forKey: .bodyBatteryScore)
        try values.encodeIfPresent(sleepDurationSeconds, forKey: .sleepDurationSeconds)
        try values.encodeIfPresent(hrvMilliseconds, forKey: .hrvMilliseconds)
        try values.encodeIfPresent(restingHeartRateBPM, forKey: .restingHeartRateBPM)
        try values.encodeIfPresent(steps, forKey: .steps)
        try values.encodeIfPresent(activeEnergyKcal, forKey: .activeEnergyKcal)
    }

    var localDayDisplayText: String {
        guard !localDayKey.isEmpty else { return localDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) }
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
            if !$0.localDayKey.isEmpty && !candidate.localDayKey.isEmpty {
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
