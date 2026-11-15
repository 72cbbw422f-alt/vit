import Foundation

struct SleepInterval {
    let start: Date
    let end: Date
}

enum SleepSessionCalculator {
    /// Merges overlapping asleep-stage intervals and groups sleep segments separated
    /// by no more than the configured wake gap. Returns the duration of the latest group.
    static func latestSessionDuration(
        intervals: [SleepInterval],
        maximumWakeGap: TimeInterval = 90 * 60
    ) -> TimeInterval? {
        let valid = intervals
            .filter { $0.end > $0.start }
            .sorted { $0.start < $1.start }
        guard let first = valid.first else { return nil }

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

        var sessions: [SleepInterval] = []
        guard let firstMerged = merged.first else { return nil }
        currentStart = firstMerged.start
        currentEnd = firstMerged.end

        for interval in merged.dropFirst() {
            if interval.start.timeIntervalSince(currentEnd) <= maximumWakeGap {
                currentEnd = interval.end
            } else {
                sessions.append(SleepInterval(start: currentStart, end: currentEnd))
                currentStart = interval.start
                currentEnd = interval.end
            }
        }
        sessions.append(SleepInterval(start: currentStart, end: currentEnd))

        guard let latest = sessions.last else { return nil }
        let duration = latest.end.timeIntervalSince(latest.start)
        return duration > 0 ? duration : nil
    }
}
