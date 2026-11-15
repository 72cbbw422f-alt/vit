import XCTest
@testable import VITALCore

final class SleepSessionCalculatorTests: XCTestCase {
    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 15, hour: hour, minute: minute))!
    }

    func testOverlappingSleepStagesAreNotDoubleCounted() {
        let intervals = [
            SleepInterval(start: date(23), end: date(2)),
            SleepInterval(start: date(0), end: date(1, 30))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testAdjacentStagesAreMergedIntoOneSession() {
        let intervals = [
            SleepInterval(start: date(22), end: date(23)),
            SleepInterval(start: date(23), end: date(1))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testLatestSessionSelectedAfterLongAwakeGap() {
        let intervals = [
            SleepInterval(start: date(1), end: date(3)),
            SleepInterval(start: date(8), end: date(9, 30))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 90 * 60)
    }

    func testInvalidIntervalsAreIgnored() {
        let intervals = [
            SleepInterval(start: date(23), end: date(22)),
            SleepInterval(start: date(22), end: date(23))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3600)
    }

    func testEmptyIntervalsReturnNil() {
        XCTAssertNil(SleepSessionCalculator.latestSessionDuration(intervals: []))
    }
}
