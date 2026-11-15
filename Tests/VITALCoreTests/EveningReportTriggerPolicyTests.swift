import XCTest
@testable import VITALCore

final class EveningReportTriggerPolicyTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return value
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testBeforeDefaultTimeDoesNotTrigger() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(15, 20, 59), reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testAtDefaultTimeTriggers() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(15, 21), reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testAfterDefaultTimeTriggers() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(15, 22, 15), reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testDifferentLocalDayDoesNotTrigger() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(16, 21), reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testCustomHourIsSupported() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(15, 20), reportDay: date(15, 0), hour: 20, calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testInvalidHourDoesNotTrigger() {
        let result = EveningReportTriggerPolicy.evaluate(
            eventDate: date(15, 21), reportDay: date(15, 0), hour: 24, calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }
}
