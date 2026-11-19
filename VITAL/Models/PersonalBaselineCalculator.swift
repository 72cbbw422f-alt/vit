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


struct TrendComparison {
    let recentMedian: Double?
    let previousMedian: Double?
    let recentSampleCount: Int
    let previousSampleCount: Int

    var changePercent: Double? {
        guard let recentMedian, let previousMedian,
              recentMedian.isFinite, previousMedian.isFinite, previousMedian > 0 else { return nil }
        let change = (recentMedian - previousMedian) / previousMedian * 100
        return change.isFinite ? change : nil
    }

    var hasEnoughData: Bool { recentMedian != nil && previousMedian != nil }
}

enum TrendComparisonCalculator {
    static let minimumSamplesPerPeriod = 2

    /// Compares medians from two adjacent, equal-length periods ending at endDate.
    /// Periods are half-open: [end-days, end) and [end-2*days, end-days).
    static func compare(
        samples: [DailyBaselineSample],
        endDate: Date,
        periodDays: Int = 7,
        calendar: Calendar = .current
    ) -> TrendComparison {
        guard periodDays > 0,
              let recentStart = calendar.date(byAdding: .day, value: -periodDays, to: endDate),
              let previousStart = calendar.date(byAdding: .day, value: -periodDays * 2, to: endDate) else {
            return TrendComparison(recentMedian: nil, previousMedian: nil, recentSampleCount: 0, previousSampleCount: 0)
        }
        let valid = samples.filter { $0.value.isFinite && $0.value > 0 }
        let recent = valid.filter { $0.day >= recentStart && $0.day < endDate }.map(\.value)
        let previous = valid.filter { $0.day >= previousStart && $0.day < recentStart }.map(\.value)
        func median(_ values: [Double]) -> Double? {
            guard values.count >= minimumSamplesPerPeriod else { return nil }
            let sorted = values.sorted()
            let middle = sorted.count / 2
            if sorted.count.isMultiple(of: 2) {
                return sorted[middle - 1] + (sorted[middle] - sorted[middle - 1]) / 2
            }
            return sorted[middle]
        }
        return TrendComparison(
            recentMedian: median(recent),
            previousMedian: median(previous),
            recentSampleCount: recent.count,
            previousSampleCount: previous.count
        )
    }
}
