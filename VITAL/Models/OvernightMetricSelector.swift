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
        heartRate: [TimedHealthValue] = [],
        sleepSession: SleepSession
    ) -> OvernightMetrics {
        let hrvValues = validValues(hrv, during: sleepSession, range: 1...300)
        let restingValues = validValues(restingHeartRate, during: sleepSession, range: 25...220)
        // Apple Health's restingHeartRate samples are not guaranteed to be timestamped
        // inside the sleep session. Bevel-style fallback: derive a nightly pulse proxy
        // from actual heart-rate samples collected during that same sleep session.
        // This is explicitly a proxy, not an Apple Health resting-heart-rate sample.
        let sleepHeartRateValues = validValues(heartRate, during: sleepSession, range: 25...220)
        let nightlyPulse = median(restingValues) ?? mean(sleepHeartRateValues)
        return OvernightMetrics(
            hrvMilliseconds: median(hrvValues),
            restingHeartRateBPM: nightlyPulse,
            hrvSampleCount: hrvValues.count,
            restingHeartRateSampleCount: restingValues.isEmpty ? sleepHeartRateValues.count : restingValues.count
        )
    }

    private static func validValues(
        _ samples: [TimedHealthValue],
        during session: SleepSession,
        range: ClosedRange<Double>
    ) -> [Double] {
        samples.compactMap { sample in
            guard sample.timestamp >= session.start,
                  sample.timestamp <= session.end,
                  sample.value.isFinite,
                  range.contains(sample.value) else { return nil }
            return sample.value
        }
    }

    private static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let result = values.reduce(0, +) / Double(values.count)
        return result.isFinite ? result : nil
    }

    private static func median(_ values: [Double]) -> Double? {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            let lower = sorted[middle - 1]
            let upper = sorted[middle]
            return lower + (upper - lower) / 2
        }
        return sorted[middle]
    }
}
