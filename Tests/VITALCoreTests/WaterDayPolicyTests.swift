import XCTest
@testable import VITALCore

final class WaterDayPolicyTests: XCTestCase {
    private var stockholm: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return calendar
    }

    func testMissingSavedDayRequiresReset() {
        XCTAssertTrue(WaterDayPolicy.shouldReset(savedDay: nil, now: .now, calendar: stockholm))
    }

    func testSameLocalDayDoesNotResetEvenWhenTimesDiffer() {
        let calendar = stockholm
        let saved = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 0, minute: 5))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 23, minute: 55))!
        XCTAssertFalse(WaterDayPolicy.shouldReset(savedDay: saved, now: now, calendar: calendar))
    }

    func testNextLocalDayResetsLedger() {
        let calendar = stockholm
        let saved = calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 23, minute: 59))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 0, minute: 1))!
        XCTAssertTrue(WaterDayPolicy.shouldReset(savedDay: saved, now: now, calendar: calendar))
    }

    func testDaylightSavingTransitionUsesCalendarDayNotFixedDuration() {
        let calendar = stockholm
        let saved = calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 29, hour: 12))!
        XCTAssertEqual(now.timeIntervalSince(saved), 23 * 60 * 60)
        XCTAssertTrue(WaterDayPolicy.shouldReset(savedDay: saved, now: now, calendar: calendar))
    }

    func testOnlySupportedWaterAmountsAreAccepted() {
        XCTAssertTrue(WaterDayPolicy.isValidAmount(150))
        XCTAssertTrue(WaterDayPolicy.isValidAmount(250))
        XCTAssertTrue(WaterDayPolicy.isValidAmount(500))
        XCTAssertFalse(WaterDayPolicy.isValidAmount(0))
        XCTAssertFalse(WaterDayPolicy.isValidAmount(200))
        XCTAssertFalse(WaterDayPolicy.isValidAmount(750))
    }
}
