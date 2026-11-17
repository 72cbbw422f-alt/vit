import Foundation

struct DailyBaselineSample {
    let day: Date
    let value: Double
}

struct PersonalBaseline {
    let median: Double?
    let validDays: Int
    let windowStart: Date
    let windowEnd: Date
    let isReady: Bool
}

enum PersonalBaselineCalculator {
    static let minimumValidDays = 14

    /// Calculates a median from daily values in the half-open interval [windowStart, windowEnd).
    /// Multiple samples on one calendar day are reduced to that day's median first.
    static func calculate(
        samples: [DailyBaselineSample],
        windowStart: Date,
        windowEnd: Date,
        calendar: Calendar = .current
    ) -> PersonalBaseline {
        guard windowEnd > windowStart else {
            return PersonalBaseline(median: nil, validDays: 0,
                windowStart: windowStart, windowEnd: windowEnd, isReady: false)
        }

        let valid = samples.filter {
            $0.value.isFinite && $0.value > 0 &&
            $0.day >= windowStart && $0.day < windowEnd
        }
        let grouped = Dictionary(grouping: valid) { calendar.startOfDay(for: $0.day) }
        let dailyValues = grouped.values.compactMap { values -> Double? in
            median(values.map(\.value))
        }
        let result = median(dailyValues)
        return PersonalBaseline(
            median: dailyValues.count >= minimumValidDays ? result : nil,
            validDays: dailyValues.count,
            windowStart: windowStart,
            windowEnd: windowEnd,
            isReady: dailyValues.count >= minimumValidDays
        )
    }

    private static func median(_ values: [Double]) -> Double? {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            let lower = sorted[middle - 1]
            let upper = sorted[middle]
            // Avoid overflowing when two large, finite HealthKit values are averaged.
            return lower + (upper - lower) / 2
        }
        return sorted[middle]
    }
}
