import XCTest
@testable import VITALCore

final class PersonalBaselineCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 1 + offset))!
    }

    func testRequiresFourteenDistinctValidDays() {
        let samples = (0..<13).map { DailyBaselineSample(day: day($0), value: 50) }
        let result = PersonalBaselineCalculator.calculate(samples: samples, windowStart: day(0), windowEnd: day(30), calendar: calendar)
        XCTAssertFalse(result.isReady)
        XCTAssertNil(result.median)
        XCTAssertEqual(result.validDays, 13)
    }

    func testCalculatesMedianFromFourteenDays() {
        let samples = (0..<14).map { DailyBaselineSample(day: day($0), value: Double($0 + 1)) }
        let result = PersonalBaselineCalculator.calculate(samples: samples, windowStart: day(0), windowEnd: day(30), calendar: calendar)
        XCTAssertTrue(result.isReady)
        XCTAssertEqual(result.median, 7.5)
        XCTAssertEqual(result.validDays, 14)
    }

    func testMultipleSamplesOnSameDayCountAsOneDay() {
        let samples = [
            DailyBaselineSample(day: day(0), value: 40),
            DailyBaselineSample(day: day(0).addingTimeInterval(3600), value: 60)
        ] + (1..<14).map { DailyBaselineSample(day: day($0), value: 50) }
        let result = PersonalBaselineCalculator.calculate(samples: samples, windowStart: day(0), windowEnd: day(30), calendar: calendar)
        XCTAssertEqual(result.validDays, 14)
        XCTAssertEqual(result.median, 50)
    }

    func testIgnoresInvalidAndOutOfWindowValues() {
        let samples = (0..<14).map { DailyBaselineSample(day: day($0), value: 50) } + [
            DailyBaselineSample(day: day(15), value: 900),
            DailyBaselineSample(day: day(2), value: .nan),
            DailyBaselineSample(day: day(3), value: -2)
        ]
        let result = PersonalBaselineCalculator.calculate(samples: samples, windowStart: day(0), windowEnd: day(14), calendar: calendar)
        XCTAssertEqual(result.validDays, 14)
        XCTAssertEqual(result.median, 50)
    }

    func testMedianOfLargeFiniteValuesRemainsFinite() {
        let samples = (0..<14).map { DailyBaselineSample(day: day($0), value: Double.greatestFiniteMagnitude) }
        let result = PersonalBaselineCalculator.calculate(samples: samples, windowStart: day(0), windowEnd: day(30), calendar: calendar)
        XCTAssertTrue(result.isReady)
        XCTAssertEqual(result.median, Double.greatestFiniteMagnitude)
        XCTAssertTrue(result.median?.isFinite == true)
    }

    func testInvalidWindowReturnsNotReady() {
        let result = PersonalBaselineCalculator.calculate(samples: [], windowStart: day(10), windowEnd: day(0), calendar: calendar)
        XCTAssertFalse(result.isReady)
        XCTAssertNil(result.median)
    }

    func testTrendComparisonUsesAdjacentSevenDayMedians() {
        let end = day(20)
        let samples = [
            DailyBaselineSample(day: day(7), value: 50),
            DailyBaselineSample(day: day(8), value: 60),
            DailyBaselineSample(day: day(9), value: 70),
            DailyBaselineSample(day: day(14), value: 70),
            DailyBaselineSample(day: day(15), value: 80),
            DailyBaselineSample(day: day(16), value: 90)
        ]
        let result = TrendComparisonCalculator.compare(samples: samples, endDate: end, periodDays: 7, calendar: calendar)
        XCTAssertEqual(result.previousMedian, 60)
        XCTAssertEqual(result.recentMedian, 80)
        XCTAssertEqual(result.changePercent ?? 0, 100.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(result.previousSampleCount, 3)
        XCTAssertEqual(result.recentSampleCount, 3)
    }

    func testTrendComparisonRequiresTwoSamplesInEachPeriod() {
        let end = day(20)
        let samples = [
            DailyBaselineSample(day: day(14), value: 70),
            DailyBaselineSample(day: day(15), value: 80),
            DailyBaselineSample(day: day(7), value: 60)
        ]
        let result = TrendComparisonCalculator.compare(samples: samples, endDate: end, calendar: calendar)
        XCTAssertFalse(result.hasEnoughData)
        XCTAssertNil(result.changePercent)
        XCTAssertEqual(result.recentSampleCount, 2)
        XCTAssertEqual(result.previousSampleCount, 1)
    }

    func testTrendComparisonIgnoresInvalidValuesAndPeriodBoundaries() {
        let end = day(20)
        let samples = [
            DailyBaselineSample(day: day(6), value: 100),
            DailyBaselineSample(day: day(7), value: 40),
            DailyBaselineSample(day: day(8), value: .nan),
            DailyBaselineSample(day: day(9), value: -1),
            DailyBaselineSample(day: day(14), value: 60),
            DailyBaselineSample(day: day(15), value: 80)
        ]
        let result = TrendComparisonCalculator.compare(samples: samples, endDate: end, calendar: calendar)
        XCTAssertEqual(result.previousSampleCount, 1)
        XCTAssertEqual(result.recentSampleCount, 2)
        XCTAssertFalse(result.hasEnoughData)
    }

    func testTrendComparisonHandlesZeroPreviousMedianSafely() {
        let comparison = TrendComparison(recentMedian: 10, previousMedian: 0, recentSampleCount: 2, previousSampleCount: 2)
        XCTAssertNil(comparison.changePercent)
    }

}
