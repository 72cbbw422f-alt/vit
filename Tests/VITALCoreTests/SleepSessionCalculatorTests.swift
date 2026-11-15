import XCTest
@testable import VITALCore

final class SleepSessionCalculatorTests: XCTestCase {
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testOverlappingSleepStagesAreNotDoubleCounted() {
        let intervals = [
            SleepInterval(start: date(14, 23), end: date(15, 2)),
            SleepInterval(start: date(15, 0), end: date(15, 1, 30))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testAdjacentStagesAreMergedIntoOneSession() {
        let intervals = [
            SleepInterval(start: date(14, 22), end: date(14, 23)),
            SleepInterval(start: date(14, 23), end: date(15, 1))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testLatestSessionSelectedAfterLongAwakeGap() {
        let intervals = [
            SleepInterval(start: date(15, 1), end: date(15, 3)),
            SleepInterval(start: date(15, 8), end: date(15, 9, 30))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 90 * 60)
    }

    func testInvalidIntervalsAreIgnored() {
        let intervals = [
            SleepInterval(start: date(15, 23), end: date(15, 22)),
            SleepInterval(start: date(15, 22), end: date(15, 23))
        ]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3600)
    }

    func testEmptyIntervalsReturnNil() {
        XCTAssertNil(SleepSessionCalculator.latestSessionDuration(intervals: []))
    }
}
