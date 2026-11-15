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

    func testInvalidWindowReturnsNotReady() {
        let result = PersonalBaselineCalculator.calculate(samples: [], windowStart: day(10), windowEnd: day(0), calendar: calendar)
        XCTAssertFalse(result.isReady)
        XCTAssertNil(result.median)
    }
}
