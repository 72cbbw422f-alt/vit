import XCTest
@testable import VITALCore

final class OvernightMetricSelectorTests: XCTestCase {
    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 15, hour: hour, minute: minute))!
    }
    private var session: SleepSession { SleepSession(start: date(23), end: date(7)) }

    func testUsesOnlySamplesInsideSleepSession() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(1), value: 40), TimedHealthValue(timestamp: date(3), value: 60), TimedHealthValue(timestamp: date(8), value: 99)],
            restingHeartRate: [TimedHealthValue(timestamp: date(2), value: 50), TimedHealthValue(timestamp: date(12), value: 80)],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 50)
        XCTAssertEqual(result.restingHeartRateBPM, 50)
        XCTAssertEqual(result.hrvSampleCount, 2)
        XCTAssertEqual(result.restingHeartRateSampleCount, 1)
    }

    func testDoesNotInventValuesWhenNoOvernightSamplesExist() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(12), value: 40)],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertNil(result.hrvMilliseconds)
        XCTAssertNil(result.restingHeartRateBPM)
        XCTAssertEqual(result.hrvSampleCount, 0)
        XCTAssertEqual(result.restingHeartRateSampleCount, 0)
    }

    func testIgnoresInvalidValues() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(1), value: .nan), TimedHealthValue(timestamp: date(2), value: -1), TimedHealthValue(timestamp: date(3), value: 55)],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 55)
        XCTAssertEqual(result.hrvSampleCount, 1)
    }

    func testIncludesExactSleepBoundaries() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(23), value: 40), TimedHealthValue(timestamp: date(7), value: 60)],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 50)
    }
}