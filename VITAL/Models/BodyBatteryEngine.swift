import Foundation

/// Conservative daytime energy estimate, kept separate from overnight recovery.
/// Sustained low heart rate can add a small recovery gain; activity and elevated
/// heart rate add load. This is a heuristic wellness estimate, not a clinical metric.
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
    let recoveryGain: Double
    let explanation: String
}

enum BodyBatteryEngine {
    static let maximumHeartRateGap: TimeInterval = 15 * 60
    static let minimumHeartRateSamples = 3
    static let minimumHeartRateSpan: TimeInterval = 30 * 60
    static let recoveryHeartRateMarginBPM = 5.0
    static let recoveryPointsPerHour = 1.5
    static let maximumDailyRecoveryGain = 12.0

    /// Estimates daytime capacity from overnight recovery.
    /// Gaps longer than 15 minutes are ignored. Rest gain is awarded only when
    /// both bounding HR samples are near the personal resting baseline and no
    /// active-energy sample overlaps the interval.
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
                activeEnergyKcal: 0, cardiovascularLoad: 0, activityLoad: 0, recoveryGain: 0,
                explanation: "För få pulsmätningar för att uppskatta kroppsbatteriet.")
        }

        var cardiovascularLoad = 0.0
        var recoveryHours = 0.0
        for index in 0..<(heartRates.count - 1) {
            let current = heartRates[index]
            let next = heartRates[index + 1]
            let interval = next.timestamp.timeIntervalSince(current.timestamp)
            guard interval > 0, interval <= maximumHeartRateGap else { continue }
            let hours = interval / 3600
            let elevation = max(current.value - resting, 0)
            cardiovascularLoad += (elevation / 60) * hours * 18
            let nextElevation = max(next.value - resting, 0)
            let averageHeartRate = (current.value + next.value) / 2
            let hasActivity = energySamples.contains { sample in
                guard Self.isValidEnergySample(sample) else { return false }
                let sampleStart = sample.startTimestamp ?? sample.timestamp
                return sampleStart < next.timestamp && sample.timestamp > current.timestamp
            }
            if averageHeartRate <= resting + recoveryHeartRateMarginBPM,
               nextElevation <= recoveryHeartRateMarginBPM, !hasActivity {
                recoveryHours += hours
            }
        }

        let energySamples = Self.nonOverlappingEnergySamples(
            input.activeEnergySamples,
            wakeTime: input.wakeTime,
            asOf: input.asOf
        )
        let energy = energySamples.reduce(0) { $0 + $1.value }
        guard energy.isFinite, cardiovascularLoad.isFinite else {
            return BodyBatteryResult(score: nil, heartRateSampleCount: heartRates.count,
                activeEnergyKcal: 0, cardiovascularLoad: 0, activityLoad: 0, recoveryGain: 0,
                explanation: "Hälsodata innehåller orimliga värden för att beräkna kroppsbatteriet.")
        }
        let activityLoad = energy * 0.025
        let recoveryGain = min(recoveryHours * recoveryPointsPerHour, maximumDailyRecoveryGain)
        let totalLoad = cardiovascularLoad + activityLoad
        let rawScore = Double(start) - totalLoad + recoveryGain
        guard rawScore.isFinite else {
            return BodyBatteryResult(score: nil, heartRateSampleCount: heartRates.count,
                activeEnergyKcal: 0, cardiovascularLoad: 0, activityLoad: 0, recoveryGain: 0,
                explanation: "Hälsodata innehåller orimliga värden för att beräkna kroppsbatteriet.")
        }
        let score = max(0, min(100, Int(rawScore.rounded())))

        return BodyBatteryResult(score: score, heartRateSampleCount: heartRates.count,
            activeEnergyKcal: energy, cardiovascularLoad: cardiovascularLoad,
            activityLoad: activityLoad, recoveryGain: recoveryGain,
            explanation: "Provisorisk uppskattning från morgonens återhämtning, pulsbelastning, aktiv energi och sammanhängande viloperioder. Beräkningen är en förenklad välmåendemodell.")
    }

    private static func nonOverlappingEnergySamples(
        _ samples: [TimedHealthValue],
        wakeTime: Date,
        asOf: Date
    ) -> [TimedHealthValue] {
        let candidates = samples.filter { sample in
            let start = sample.startTimestamp ?? sample.timestamp
            return isValidEnergySample(sample) && start >= wakeTime && sample.timestamp <= asOf
        }.sorted {
            let lhsStart = $0.startTimestamp ?? $0.timestamp
            let rhsStart = $1.startTimestamp ?? $1.timestamp
            if lhsStart == rhsStart { return $0.timestamp < $1.timestamp }
            return lhsStart < rhsStart
        }

        var accepted: [TimedHealthValue] = []
        var occupiedUntil = wakeTime
        for sample in candidates {
            let start = sample.startTimestamp ?? sample.timestamp
            // HealthKit may return overlapping energy intervals from multiple sources.
            // Keep the first interval and conservatively discard later overlaps.
            guard start >= occupiedUntil else { continue }
            accepted.append(sample)
            occupiedUntil = max(occupiedUntil, sample.timestamp)
        }
        return accepted
    }

    private static func isValidEnergySample(_ sample: TimedHealthValue) -> Bool {
        guard sample.value.isFinite, sample.value > 0 else { return false }
        if let start = sample.startTimestamp {
            return start < sample.timestamp
        }
        return true
    }

    private static func unavailable(_ explanation: String) -> BodyBatteryResult {
        BodyBatteryResult(score: nil, heartRateSampleCount: 0, activeEnergyKcal: 0,
            cardiovascularLoad: 0, activityLoad: 0, recoveryGain: 0, explanation: explanation)
    }
}
