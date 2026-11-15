import XCTest
@testable import VITALCore

final class MorningReportTriggerPolicyTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return value
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private var mainSleep: SleepSession {
        SleepSession(start: date(14, 22, 30), end: date(15, 6, 30))
    }

    func testSleepFocusEndTriggersAfterSettlingInterval() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .sleepFocusEnded, eventDate: date(15, 6, 50),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testHealthKitUpdateCanActAsFallbackTrigger() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .healthKitSleepUpdated, eventDate: date(15, 7),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testAppActivationCanActAsFallbackTrigger() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .appBecameActive, eventDate: date(15, 9),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.shouldCreateSnapshot)
    }

    func testDoesNotTriggerBeforeSleepHasEnded() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .sleepFocusEnded, eventDate: date(15, 6),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testWaitsForHealthDataSettlingIntervalAfterWake() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .healthKitSleepUpdated, eventDate: date(15, 6, 49),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
        XCTAssertTrue(result.reason.contains("20 minuter"))
    }

    func testShortNapDoesNotTriggerMorningReport() {
        let nap = SleepSession(start: date(15, 13), end: date(15, 14, 30))
        let result = MorningReportTriggerPolicy.evaluate(
            source: .healthKitSleepUpdated, eventDate: date(15, 14, 55),
            mainSleep: nap, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testStaleSleepSessionDoesNotTriggerReport() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .appBecameActive, eventDate: date(16, 8),
            mainSleep: mainSleep, reportDay: date(16, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testWakeUpMustBelongToRequestedLocalReportDay() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .sleepFocusEnded, eventDate: date(15, 7),
            mainSleep: mainSleep, reportDay: date(14, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }

    func testDecisionReasonNamesActualTriggerSource() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .healthKitSleepUpdated, eventDate: date(15, 7),
            mainSleep: mainSleep, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertTrue(result.reason.contains("Apple Hälsa registrerade en sömnuppdatering"))
    }

    func testMissingSleepDataNeverCreatesReport() {
        let result = MorningReportTriggerPolicy.evaluate(
            source: .sleepFocusEnded, eventDate: date(15, 7),
            mainSleep: nil, reportDay: date(15, 0), calendar: calendar
        )
        XCTAssertFalse(result.shouldCreateSnapshot)
    }
}
