import Foundation

struct SleepEfficiencySummary: Equatable {
    let asleepDuration: TimeInterval
    let inBedDuration: TimeInterval
    let percentage: Double
}

enum SleepEfficiencyCalculator {
    /// Requires one recorded in-bed interval to cover the complete selected sleep session.
    static func calculate(session: SleepSession, inBedIntervals: [SleepInterval]) -> SleepEfficiencySummary? {
        guard session.end > session.start, session.duration > 0 else { return nil }
        let covering = inBedIntervals
            .filter { $0.end > $0.start && $0.start <= session.start && $0.end >= session.end }
            .min { $0.end.timeIntervalSince($0.start) < $1.end.timeIntervalSince($1.start) }
        guard let bed = covering else { return nil }
        let bedDuration = bed.end.timeIntervalSince(bed.start)
        guard bedDuration > 0, session.duration <= bedDuration else { return nil }
        return SleepEfficiencySummary(asleepDuration: session.duration, inBedDuration: bedDuration,
                                      percentage: min(100, max(0, session.duration / bedDuration * 100)))
    }
}

struct SleepRegularitySummary: Equatable {
    let nights: Int
    let sleepStartVariabilityMinutes: Double
    let wakeTimeVariabilityMinutes: Double
}

enum SleepRegularityCalculator {
    static let minimumNights = 5

    /// Circular clock-time distance treats 23:50 and 00:10 as 20 minutes apart.
    /// Variability is mean absolute deviation from the circular mean, not a health score.
    static func calculate(sessions: [SleepSession], calendar: Calendar = .current) -> SleepRegularitySummary? {
        let valid = sessions.filter { $0.end > $0.start && $0.duration > 0 }
        guard valid.count >= minimumNights,
              let start = variability(for: valid.map { clockMinutes($0.start, calendar: calendar) }),
              let wake = variability(for: valid.map { clockMinutes($0.end, calendar: calendar) }) else { return nil }
        return SleepRegularitySummary(nights: valid.count, sleepStartVariabilityMinutes: start,
                                      wakeTimeVariabilityMinutes: wake)
    }

    private static func clockMinutes(_ date: Date, calendar: Calendar) -> Double {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double((parts.hour ?? 0) * 60 + (parts.minute ?? 0)) + Double(parts.second ?? 0) / 60
    }

    private static func variability(for values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let angles = values.map { $0 / 1440 * 2 * Double.pi }
        let sinMean = angles.map(sin).reduce(0, +) / Double(angles.count)
        let cosMean = angles.map(cos).reduce(0, +) / Double(angles.count)
        guard hypot(sinMean, cosMean) > 0.000001 else { return nil }
        let mean = atan2(sinMean, cosMean)
        let meanMinutes = (mean >= 0 ? mean : mean + 2 * Double.pi) / (2 * Double.pi) * 1440
        return values.map { value in
            let difference = abs(value - meanMinutes)
            return min(difference, 1440 - difference)
        }.reduce(0, +) / Double(values.count)
    }
}
