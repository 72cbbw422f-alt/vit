import Foundation

/// First conservative daytime energy estimate, kept separate from overnight recovery.
/// The model only decreases from the morning recovery score; daytime recharge is
/// intentionally deferred until it can be validated against real-world data.
struct BodyBatteryInputs {
    let wakeTime: Date
    let asOf: Date
    let overnightRecoveryScore: Int?
    let restingHeartRateBaselineBPM: Double?
    let heartRateSamples: [TimedHealthValue]
    let activeEnergySamples: [TimedHealthValue]
}

struct BodyBatteryResult {
    let score: Int?
    let heartRateSampleCount: Int
    let activeEnergyKcal: Double
    let cardiovascularLoad: Double
    let activityLoad: Double
    let explanation: String
}

enum BodyBatteryEngine {
    static let maximumHeartRateGap: TimeInterval = 15 * 60
    static let minimumHeartRateSamples = 3
    static let minimumHeartRateSpan: TimeInterval = 30 * 60

    /// Estimates remaining daytime capacity from the morning recovery score.
    /// HR load integrates elevation above personal resting HR over sample intervals;
    /// active energy contributes a separate, deliberately modest load term.
    static func calculate(_ input: BodyBatteryInputs) -> BodyBatteryResult {
        guard input.asOf >= input.wakeTime,
              let start = input.overnightRecoveryScore,
              (0...100).contains(start),
              let resting = input.restingHeartRateBaselineBPM,
              resting.isFinite, resting > 0 else {
            return unavailable("Saknar giltig morgonspoäng eller personlig vilopulsbaslinje.")
        }

        let heartRates = input.heartRateSamples
            .filter { $0.timestamp >= input.wakeTime && $0.timestamp <= input.asOf &&
                $0.value.isFinite && $0.value > 0 && $0.value < 250 }
            .sorted { $0.timestamp < $1.timestamp }

        guard heartRates.count >= minimumHeartRateSamples,
              let first = heartRates.first, let last = heartRates.last,
              last.timestamp.timeIntervalSince(first.timestamp) >= minimumHeartRateSpan else {
            return BodyBatteryResult(score: nil, heartRateSampleCount: heartRates.count,
                activeEnergyKcal: 0, cardiovascularLoad: 0, activityLoad: 0,
                explanation: "För få pulsmätningar för att uppskatta kroppsbatteriet.")
        }

        var cardiovascularLoad = 0.0
        for index in 0..<(heartRates.count - 1) {
            let current = heartRates[index]
            let next = heartRates[index + 1]
            let interval = next.timestamp.timeIntervalSince(current.timestamp)
            guard interval > 0, interval <= maximumHeartRateGap else { continue }
            let hours = interval / 3600
            let elevation = max(current.value - resting, 0)
            cardiovascularLoad += (elevation / 60) * hours * 18
        }

        let energy = input.activeEnergySamples
            .filter { $0.timestamp >= input.wakeTime && $0.timestamp <= input.asOf &&
                $0.value.isFinite && $0.value > 0 }
            .reduce(0) { $0 + $1.value }
        let activityLoad = energy * 0.025
        let totalLoad = cardiovascularLoad + activityLoad
        let score = max(0, min(100, Int((Double(start) - totalLoad).rounded())))

        return BodyBatteryResult(score: score, heartRateSampleCount: heartRates.count,
            activeEnergyKcal: energy, cardiovascularLoad: cardiovascularLoad,
            activityLoad: activityLoad,
            explanation: "Provisorisk uppskattning från morgonens återhämtning, pulsbelastning och aktiv energi. Modellen laddar ännu inte upp under vila.")
    }

    private static func unavailable(_ explanation: String) -> BodyBatteryResult {
        BodyBatteryResult(score: nil, heartRateSampleCount: 0, activeEnergyKcal: 0,
            cardiovascularLoad: 0, activityLoad: 0, explanation: explanation)
    }
}
