import XCTest
@testable import VITALCore

final class SleepSessionCalculatorTests: XCTestCase {
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func testOverlappingSleepStagesAreNotDoubleCounted() {
        let intervals = [SleepInterval(start: date(14, 23), end: date(15, 2)), SleepInterval(start: date(15, 0), end: date(15, 1, 30))]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testAdjacentStagesAreMergedIntoOneSession() {
        let intervals = [SleepInterval(start: date(14, 22), end: date(14, 23)), SleepInterval(start: date(14, 23), end: date(15, 1))]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3 * 3600)
    }

    func testAwakeGapIsGroupedButNotCountedAsSleep() {
        let intervals = [SleepInterval(start: date(14, 22), end: date(15, 1)), SleepInterval(start: date(15, 1, 30), end: date(15, 6))]
        let session = SleepSessionCalculator.primarySession(intervals: intervals)
        XCTAssertEqual(session?.start, date(14, 22))
        XCTAssertEqual(session?.end, date(15, 6))
        XCTAssertEqual(session?.duration, 7.5 * 3600)
    }

    func testLatestWakeDateWinsOverLongerPreviousNight() {
        let intervals = [
            SleepInterval(start: date(13, 21), end: date(14, 6)),
            SleepInterval(start: date(14, 23), end: date(15, 5, 30))
        ]
        let selected = SleepSessionCalculator.primarySession(intervals: intervals)
        XCTAssertEqual(selected?.start, date(15, 0))
        XCTAssertEqual(selected?.duration, 5.5 * 3600)
    }

    func testMainSleepWinsOverLaterNapOnSameWakeDate() {
        let intervals = [
            SleepInterval(start: date(14, 22), end: date(15, 6, 30)),
            SleepInterval(start: date(15, 13), end: date(15, 14))
        ]
        let selected = SleepSessionCalculator.primarySession(intervals: intervals)
        XCTAssertEqual(selected?.start, date(14, 22))
        XCTAssertEqual(selected?.end, date(15, 6, 30))
    }

    func testPrimarySessionUsesLatestEndWhenDurationsTieOnSameDay() {
        let intervals = [
            SleepInterval(start: date(15, 1), end: date(15, 3)),
            SleepInterval(start: date(15, 8), end: date(15, 10))
        ]
        let selected = SleepSessionCalculator.primarySession(intervals: intervals)
        XCTAssertEqual(selected?.start, date(15, 8))
    }

    func testLegacySleepSessionInitializerStillDefaultsToElapsedDuration() {
        let session = SleepSession(start: date(14, 22), end: date(15, 6))
        XCTAssertEqual(session.duration, 8 * 3600)
    }

    func testInvalidIntervalsAreIgnored() {
        let intervals = [SleepInterval(start: date(15, 23), end: date(15, 22)), SleepInterval(start: date(15, 22), end: date(15, 23))]
        XCTAssertEqual(SleepSessionCalculator.latestSessionDuration(intervals: intervals), 3600)
    }

    func testEmptyIntervalsReturnNil() {
        XCTAssertNil(SleepSessionCalculator.latestSessionDuration(intervals: []))
    }
}
