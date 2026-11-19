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
    static let minimumPrimarySleepDuration: TimeInterval = 3 * 60 * 60

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

    /// Returns one representative main sleep per local wake-up date.
    /// When a substantial sleep exists, shorter naps are excluded; on days
    /// containing only short sessions, the longest session is retained.
    static func dailyPrimarySessions(
        intervals: [SleepInterval],
        maximumWakeGap: TimeInterval = 90 * 60,
        calendar: Calendar = .current
    ) -> [SleepSession] {
        let grouped = sessions(intervals: intervals, maximumWakeGap: maximumWakeGap)
        let byDay = Dictionary(grouping: grouped) { calendar.startOfDay(for: $0.end) }
        return byDay.keys.sorted().compactMap { day in
            guard let daySessions = byDay[day] else { return nil }
            let substantial = daySessions.filter { $0.duration >= minimumPrimarySleepDuration }
            let candidates = substantial.isEmpty ? daySessions : substantial
            return candidates.max { lhs, rhs in
                if lhs.duration == rhs.duration { return lhs.end < rhs.end }
                return lhs.duration < rhs.duration
            }
        }
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
        guard !grouped.isEmpty else { return nil }

        // A short nap after midnight must not displace the previous main sleep.
        // Prefer sessions of at least three hours, regardless of clock time;
        // this also supports shift workers who sleep during the day.
        let substantial = grouped.filter { $0.duration >= minimumPrimarySleepDuration }
        let candidates = substantial.isEmpty ? grouped : substantial
        guard let latestWakeDay = candidates.map({ calendar.startOfDay(for: $0.end) }).max() else { return nil }
        return candidates
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


enum SleepStage: Int, CaseIterable {
    case unspecified = 0
    case core = 1
    case deep = 2
    case rem = 3

    /// More specific stage data wins when HealthKit sources overlap.
    var priority: Int {
        switch self {
        case .unspecified: 0
        case .core: 1
        case .deep: 2
        case .rem: 3
        }
    }
}

struct SleepStageInterval {
    let start: Date
    let end: Date
    let stage: SleepStage
}

struct SleepStageSummary: Equatable {
    let totalAsleep: TimeInterval
    let rem: TimeInterval
    let deep: TimeInterval
    let core: TimeInterval
    let unspecified: TimeInterval

    var classifiedDuration: TimeInterval { rem + deep + core }
    var stageCoverage: Double {
        guard totalAsleep > 0 else { return 0 }
        return min(1, max(0, classifiedDuration / totalAsleep))
    }
    var hasStageData: Bool { totalAsleep > 0 }
}

enum SleepStageCalculator {
    /// Partitions the timeline at every sample boundary. Each second is counted
    /// once; overlapping samples resolve to the most specific available stage.
    static func summarize(_ intervals: [SleepStageInterval]) -> SleepStageSummary {
        let valid = intervals.filter { $0.end > $0.start }
        let boundaries = Array(Set(valid.flatMap { [$0.start, $0.end] })).sorted()
        guard boundaries.count > 1 else {
            return SleepStageSummary(totalAsleep: 0, rem: 0, deep: 0, core: 0, unspecified: 0)
        }

        var totals: [SleepStage: TimeInterval] = [:]
        for pair in zip(boundaries, boundaries.dropFirst()) {
            let start = pair.0
            let end = pair.1
            let duration = end.timeIntervalSince(start)
            guard duration > 0,
                  let selected = valid
                    .filter({ $0.start < end && $0.end > start })
                    .map(\.stage)
                    .max(by: { $0.priority < $1.priority }) else { continue }
            totals[selected, default: 0] += duration
        }

        let rem = totals[.rem, default: 0]
        let deep = totals[.deep, default: 0]
        let core = totals[.core, default: 0]
        let unspecified = totals[.unspecified, default: 0]
        return SleepStageSummary(
            totalAsleep: rem + deep + core + unspecified,
            rem: rem,
            deep: deep,
            core: core,
            unspecified: unspecified
        )
    }
}
