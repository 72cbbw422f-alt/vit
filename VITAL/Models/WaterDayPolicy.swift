import Foundation

/// Pure date and input rules for the daily water ledger.
public enum WaterDayPolicy {
    public static let allowedAmounts: Set<Int> = [150, 250, 500]

    public static func shouldReset(savedDay: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let savedDay else { return true }
        return !calendar.isDate(savedDay, inSameDayAs: now)
    }

    public static func isValidAmount(_ milliliters: Int) -> Bool {
        allowedAmounts.contains(milliliters)
    }
}
