import Foundation

struct HealthSnapshot {
    var sleepDuration: TimeInterval?
    var restingHeartRate: Double?
    var hrv: Double?
    var steps: Double?
    var activeEnergy: Double?
    var latestWeight: Double?
    var lastUpdated: Date?

    static let empty = HealthSnapshot()

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