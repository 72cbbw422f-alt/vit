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
