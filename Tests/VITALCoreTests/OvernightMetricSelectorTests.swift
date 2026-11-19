import XCTest
@testable import VITALCore

final class OvernightMetricSelectorTests: XCTestCase {
    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 15, hour: hour, minute: minute))!
    }
    private var session: SleepSession { SleepSession(start: date(23), end: date(7).addingTimeInterval(24 * 60 * 60)) }

    func testUsesOnlySamplesInsideSleepSession() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: 40), TimedHealthValue(timestamp: date(3).addingTimeInterval(24 * 60 * 60), value: 60), TimedHealthValue(timestamp: date(8).addingTimeInterval(24 * 60 * 60), value: 99)],
            restingHeartRate: [TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: 50), TimedHealthValue(timestamp: date(12).addingTimeInterval(24 * 60 * 60), value: 80)],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 50)
        XCTAssertEqual(result.restingHeartRateBPM, 50)
        XCTAssertEqual(result.hrvSampleCount, 2)
        XCTAssertEqual(result.restingHeartRateSampleCount, 1)
    }

    func testDoesNotInventValuesWhenNoOvernightSamplesExist() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(12).addingTimeInterval(24 * 60 * 60), value: 40)],
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
            hrv: [TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: .nan), TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: -1), TimedHealthValue(timestamp: date(3).addingTimeInterval(24 * 60 * 60), value: 55)],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 55)
        XCTAssertEqual(result.hrvSampleCount, 1)
    }

    func testIncludesExactSleepBoundaries() {
        let result = OvernightMetricSelector.select(
            hrv: [TimedHealthValue(timestamp: date(23), value: 40), TimedHealthValue(timestamp: date(7).addingTimeInterval(24 * 60 * 60), value: 60)],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertEqual(result.hrvMilliseconds, 50)
    }
    func testRejectsFiniteButImplausibleOvernightHRVValues() {
        let value = Double.greatestFiniteMagnitude
        let result = OvernightMetricSelector.select(
            hrv: [
                TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: value),
                TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: value)
            ],
            restingHeartRate: [],
            sleepSession: session
        )
        XCTAssertNil(result.hrvMilliseconds)
        XCTAssertEqual(result.hrvSampleCount, 0)
    }

    func testFallsBackToMeanHeartRateSamplesInsideSleepWhenNoRestingSamplesExist() {
        let result = OvernightMetricSelector.select(
            hrv: [],
            restingHeartRate: [],
            heartRate: [
                TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: 50),
                TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: 60),
                TimedHealthValue(timestamp: date(3).addingTimeInterval(24 * 60 * 60), value: 70),
                TimedHealthValue(timestamp: date(12).addingTimeInterval(24 * 60 * 60), value: 180)
            ],
            sleepSession: session
        )
        XCTAssertEqual(result.restingHeartRateBPM, 60)
        XCTAssertEqual(result.restingHeartRateSampleCount, 3)
    }

    func testPrefersHealthKitRestingHeartRateWhenAvailable() {
        let result = OvernightMetricSelector.select(
            hrv: [],
            restingHeartRate: [TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: 52)],
            heartRate: [
                TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: 80),
                TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: 90)
            ],
            sleepSession: session
        )
        XCTAssertEqual(result.restingHeartRateBPM, 52)
        XCTAssertEqual(result.restingHeartRateSampleCount, 1)
    }

    func testNightlyPulseFallbackRejectsInvalidAndOutOfSessionSamples() {
        let result = OvernightMetricSelector.select(
            hrv: [],
            restingHeartRate: [],
            heartRate: [
                TimedHealthValue(timestamp: date(1).addingTimeInterval(24 * 60 * 60), value: .nan),
                TimedHealthValue(timestamp: date(2).addingTimeInterval(24 * 60 * 60), value: 0),
                TimedHealthValue(timestamp: date(12).addingTimeInterval(24 * 60 * 60), value: 60)
            ],
            sleepSession: session
        )
        XCTAssertNil(result.restingHeartRateBPM)
        XCTAssertEqual(result.restingHeartRateSampleCount, 0)
    }

}


final class NightlyPulseBaselineCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testBuildsOneNightlyPulsePerSleepSessionUsingSameFallback() {
        let sessions = [
            SleepSession(start: date(1, 23), end: date(2, 7)),
            SleepSession(start: date(2, 23), end: date(3, 7))
        ]
        let samples = [
            TimedHealthValue(timestamp: date(2, 1), value: 50),
            TimedHealthValue(timestamp: date(2, 3), value: 60),
            TimedHealthValue(timestamp: date(3, 1), value: 60),
            TimedHealthValue(timestamp: date(3, 3), value: 70),
            TimedHealthValue(timestamp: date(3, 12), value: 180)
        ]
        let result = NightlyPulseBaselineCalculator.calculate(
            sessions: sessions, heartRateSamples: samples, calendar: calendar
        )
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].day, calendar.startOfDay(for: date(2, 7)))
        XCTAssertEqual(result[0].value, 55)
        XCTAssertEqual(result[1].value, 65)
    }

    func testDoesNotCreateBaselineDayWithoutInSessionHeartRateSamples() {
        let sessions = [SleepSession(start: date(1, 23), end: date(2, 7))]
        let result = NightlyPulseBaselineCalculator.calculate(
            sessions: sessions,
            heartRateSamples: [TimedHealthValue(timestamp: date(2, 12), value: 60)],
            calendar: calendar
        )
        XCTAssertTrue(result.isEmpty)
    }
}
