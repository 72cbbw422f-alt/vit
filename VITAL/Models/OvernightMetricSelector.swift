import Foundation

struct TimedHealthValue {
    let timestamp: Date
    let value: Double
    /// Start of the source interval when HealthKit provides one (notably active energy).
    /// Nil keeps compatibility with instantaneous or test samples.
    let startTimestamp: Date?

    init(timestamp: Date, value: Double, startTimestamp: Date? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.startTimestamp = startTimestamp
    }
}

struct OvernightMetrics {
    let hrvMilliseconds: Double?
    let restingHeartRateBPM: Double?
    let hrvSampleCount: Int
    let restingHeartRateSampleCount: Int
}

enum OvernightMetricSelector {
    /// Uses only samples whose timestamps fall inside the selected sleep session.
    /// Missing overnight samples remain nil; values from another part of the day
    /// must not be silently substituted.
    static func select(
        hrv: [TimedHealthValue],
        restingHeartRate: [TimedHealthValue],
        sleepSession: SleepSession
    ) -> OvernightMetrics {
        let hrvValues = validValues(hrv, during: sleepSession)
        let restingValues = validValues(restingHeartRate, during: sleepSession)
        return OvernightMetrics(
            hrvMilliseconds: median(hrvValues),
            restingHeartRateBPM: median(restingValues),
            hrvSampleCount: hrvValues.count,
            restingHeartRateSampleCount: restingValues.count
        )
    }

    private static func validValues(_ samples: [TimedHealthValue], during session: SleepSession) -> [Double] {
        samples.compactMap { sample in
            guard sample.timestamp >= session.start,
                  sample.timestamp <= session.end,
                  sample.value.isFinite,
                  sample.value > 0 else { return nil }
            return sample.value
        }
    }

    private static func median(_ values: [Double]) -> Double? {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}
