import Foundation

struct SleepInterval {
    let start: Date
    let end: Date
}

struct SleepSession {
    let start: Date
    let end: Date
    /// Sum of recorded asleep intervals; awake gaps are excluded.
    let asleepDuration: TimeInterval

    init(start: Date, end: Date, asleepDuration: TimeInterval? = nil) {
        self.start = start
        self.end = end
        self.asleepDuration = asleepDuration ?? max(0, end.timeIntervalSince(start))
    }

    var duration: TimeInterval { asleepDuration }
}

enum SleepSessionCalculator {
    /// Merges overlapping asleep-stage intervals and groups segments separated
    /// by no more than the configured wake gap. Grouping never counts awake gaps
    /// as sleep duration.
    static func sessions(intervals: [SleepInterval], maximumWakeGap: TimeInterval = 90 * 60) -> [SleepSession] {
        let valid = intervals.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        guard let first = valid.first else { return [] }

        var merged: [SleepInterval] = []
        var currentStart = first.start
        var currentEnd = first.end
        for interval in valid.dropFirst() {
            if interval.start <= currentEnd {
                currentEnd = max(currentEnd, interval.end)
            } else {
                merged.append(SleepInterval(start: currentStart, end: currentEnd))
                currentStart = interval.start
                currentEnd = interval.end
            }
        }
        merged.append(SleepInterval(start: currentStart, end: currentEnd))

        var result: [SleepSession] = []
        guard let firstMerged = merged.first else { return [] }
        currentStart = firstMerged.start
        currentEnd = firstMerged.end
        var asleepDuration = firstMerged.end.timeIntervalSince(firstMerged.start)

        for interval in merged.dropFirst() {
            if interval.start.timeIntervalSince(currentEnd) <= maximumWakeGap {
                asleepDuration += interval.end.timeIntervalSince(interval.start)
                currentEnd = interval.end
            } else {
                result.append(SleepSession(start: currentStart, end: currentEnd, asleepDuration: asleepDuration))
                currentStart = interval.start
                currentEnd = interval.end
                asleepDuration = interval.end.timeIntervalSince(interval.start)
            }
        }
        result.append(SleepSession(start: currentStart, end: currentEnd, asleepDuration: asleepDuration))
        return result.filter { $0.duration > 0 }
    }

    /// Selects the main sleep from the most recent local wake-up date.
    /// Within that wake-up date the longest session wins, so a later nap does
    /// not replace the night's sleep and yesterday's longer sleep cannot win
    /// over a more recent night.
    static func primarySession(
        intervals: [SleepInterval],
        maximumWakeGap: TimeInterval = 90 * 60,
        calendar: Calendar = .current
    ) -> SleepSession? {
        let grouped = sessions(intervals: intervals, maximumWakeGap: maximumWakeGap)
        guard let latestWakeDay = grouped.map({ calendar.startOfDay(for: $0.end) }).max() else { return nil }
        return grouped
            .filter { calendar.isDate($0.end, inSameDayAs: latestWakeDay) }
            .max { lhs, rhs in
                if lhs.duration == rhs.duration { return lhs.end < rhs.end }
                return lhs.duration < rhs.duration
            }
    }

    static func latestSession(intervals: [SleepInterval], maximumWakeGap: TimeInterval = 90 * 60) -> SleepSession? {
        sessions(intervals: intervals, maximumWakeGap: maximumWakeGap).last
    }

    static func latestSessionDuration(intervals: [SleepInterval], maximumWakeGap: TimeInterval = 90 * 60) -> TimeInterval? {
        latestSession(intervals: intervals, maximumWakeGap: maximumWakeGap)?.duration
    }
}
