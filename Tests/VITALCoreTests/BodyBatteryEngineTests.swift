import XCTest
@testable import VITALCore

final class BodyBatteryEngineTests: XCTestCase {
    private let wake = Date(timeIntervalSince1970: 1_800_000_000)

    func testMissingMorningRecoveryReturnsNoScore() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: nil, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([70, 72, 68]), activeEnergySamples: []
        ))
        XCTAssertNil(result.score)
    }

    func testInsufficientHeartRateCoverageReturnsNoScore() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 90, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([70, 72]), activeEnergySamples: []
        ))
        XCTAssertNil(result.score)
    }

    func testHigherHeartRateAndActivityReduceBattery() {
        let calm = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 90, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([60, 60, 60], spacing: 1800),
            activeEnergySamples: []
        ))
        let active = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 90, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([120, 120, 120], spacing: 1800),
            activeEnergySamples: [TimedHealthValue(timestamp: wake.addingTimeInterval(1200), value: 400)]
        ))
        XCTAssertNotNil(calm.score)
        XCTAssertNotNil(active.score)
        XCTAssertLessThan(active.score!, calm.score!)
    }

    func testSamplesOutsideDayAndInvalidValuesAreIgnored() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 80, restingHeartRateBaselineBPM: 60,
            heartRateSamples: [
                TimedHealthValue(timestamp: wake.addingTimeInterval(-60), value: 200),
                TimedHealthValue(timestamp: wake, value: 70),
                TimedHealthValue(timestamp: wake.addingTimeInterval(1800), value: .nan),
                TimedHealthValue(timestamp: wake.addingTimeInterval(3600), value: 70)
            ],
            activeEnergySamples: [
                TimedHealthValue(timestamp: wake.addingTimeInterval(-1), value: 500),
                TimedHealthValue(timestamp: wake.addingTimeInterval(100), value: .infinity)
            ]
        ))
        XCTAssertNil(result.score)
        XCTAssertEqual(result.heartRateSampleCount, 2)
        XCTAssertEqual(result.activeEnergyKcal, 0)
    }

    private func samples(_ values: [Double], spacing: TimeInterval = 900) -> [TimedHealthValue] {
        values.enumerated().map {
            TimedHealthValue(timestamp: wake.addingTimeInterval(Double($0.offset) * spacing), value: $0.element)
        }
    }
}
