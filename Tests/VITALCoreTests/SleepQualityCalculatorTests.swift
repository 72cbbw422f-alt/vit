import XCTest
@testable import VITALCore

final class SleepEfficiencyCalculatorTests: XCTestCase {
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testCalculatesEfficiencyOnlyWhenInBedIntervalCoversWholeSleep() {
        let session = SleepSession(start: date(14, 23), end: date(15, 6), asleepDuration: 6 * 3600)
        let result = SleepEfficiencyCalculator.calculate(session: session,
            inBedIntervals: [SleepInterval(start: date(14, 22, 30), end: date(15, 6, 30))])
        XCTAssertEqual(result?.inBedDuration, 8 * 3600)
        XCTAssertEqual(result?.asleepDuration, 6 * 3600)
        XCTAssertEqual(result?.percentage, 75)
    }

    func testDoesNotInferBedTimeWhenIntervalDoesNotCoverSession() {
        let session = SleepSession(start: date(14, 23), end: date(15, 6), asleepDuration: 6 * 3600)
        XCTAssertNil(SleepEfficiencyCalculator.calculate(session: session,
            inBedIntervals: [SleepInterval(start: date(14, 23, 15), end: date(15, 6))]))
    }

    func testRejectsInvalidOrShorterThanSleepBedInterval() {
        let session = SleepSession(start: date(14, 23), end: date(15, 6), asleepDuration: 7 * 3600)
        XCTAssertNil(SleepEfficiencyCalculator.calculate(session: session,
            inBedIntervals: [SleepInterval(start: date(14, 23), end: date(15, 6))]))
    }
}

final class SleepRegularityCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testTreatsTimesAcrossMidnightAsClose() {
        let sessions = [
            SleepSession(start: date(10, 23, 50), end: date(11, 7)),
            SleepSession(start: date(11, 0, 10), end: date(11, 7, 10)),
            SleepSession(start: date(12, 23, 55), end: date(13, 7, 5)),
            SleepSession(start: date(13, 0, 5), end: date(13, 6, 55)),
            SleepSession(start: date(14, 23, 58), end: date(15, 7, 2))
        ]
        let result = SleepRegularityCalculator.calculate(sessions: sessions, calendar: calendar)
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.sleepStartVariabilityMinutes, 15)
        XCTAssertLessThan(result!.wakeTimeVariabilityMinutes, 10)
    }

    func testRequiresAtLeastFiveValidNights() {
        let sessions = (0..<4).map { SleepSession(start: date(10 + $0, 23), end: date(11 + $0, 7)) }
        XCTAssertNil(SleepRegularityCalculator.calculate(sessions: sessions, calendar: calendar))
    }

    func testShiftWorkerDaytimeScheduleIsMeasuredWithoutNightAssumption() {
        let sessions = (0..<5).map {
            SleepSession(start: date(10 + $0, 9, $0 * 2), end: date(10 + $0, 16, $0 * 2))
        }
        let result = SleepRegularityCalculator.calculate(sessions: sessions, calendar: calendar)
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.sleepStartVariabilityMinutes, 5)
        XCTAssertLessThan(result!.wakeTimeVariabilityMinutes, 5)
    }
}
