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
            heartRateSamples: samples([60, 60, 60, 60, 60], spacing: 900),
            activeEnergySamples: []
        ))
        let active = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 90, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([120, 120, 120, 120, 120], spacing: 900),
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


    func testActiveEnergyMustBelongEntirelyToAwakeWindow() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 90, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([70, 70, 70, 70, 70], spacing: 900),
            activeEnergySamples: [
                TimedHealthValue(timestamp: wake.addingTimeInterval(300), value: 250,
                                 startTimestamp: wake.addingTimeInterval(-300)),
                TimedHealthValue(timestamp: wake.addingTimeInterval(1800), value: 100,
                                 startTimestamp: wake.addingTimeInterval(1200)),
                TimedHealthValue(timestamp: wake.addingTimeInterval(4000), value: 500,
                                 startTimestamp: wake.addingTimeInterval(3700)),
                TimedHealthValue(timestamp: wake.addingTimeInterval(2000), value: 900,
                                 startTimestamp: wake.addingTimeInterval(2500))
            ]
        ))
        XCTAssertEqual(result.activeEnergyKcal, 100, accuracy: 0.001)
    }


    func testSustainedRestNearPersonalRestingRateAddsRecovery() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 80, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([62, 62, 62, 62, 62], spacing: 900),
            activeEnergySamples: []
        ))
        XCTAssertEqual(result.recoveryGain, 1.5, accuracy: 0.001)
        XCTAssertGreaterThan(result.score ?? 0, 80)
    }

    func testActivityIntervalsDoNotEarnRestRecovery() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(3600),
            overnightRecoveryScore: 80, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples([62, 62, 62, 62, 62], spacing: 900),
            activeEnergySamples: [
                TimedHealthValue(timestamp: wake.addingTimeInterval(900), value: 20,
                                 startTimestamp: wake),
                TimedHealthValue(timestamp: wake.addingTimeInterval(1800), value: 20,
                                 startTimestamp: wake.addingTimeInterval(900)),
                TimedHealthValue(timestamp: wake.addingTimeInterval(2700), value: 20,
                                 startTimestamp: wake.addingTimeInterval(1800)),
                TimedHealthValue(timestamp: wake.addingTimeInterval(3600), value: 20,
                                 startTimestamp: wake.addingTimeInterval(2700))
            ]
        ))
        XCTAssertEqual(result.recoveryGain, 0, accuracy: 0.001)
    }

    func testDailyRecoveryGainIsCapped() {
        let result = BodyBatteryEngine.calculate(BodyBatteryInputs(
            wakeTime: wake, asOf: wake.addingTimeInterval(8 * 3600),
            overnightRecoveryScore: 80, restingHeartRateBaselineBPM: 60,
            heartRateSamples: samples(Array(repeating: 60, count: 33), spacing: 900),
            activeEnergySamples: []
        ))
        XCTAssertEqual(result.recoveryGain, BodyBatteryEngine.maximumDailyRecoveryGain, accuracy: 0.001)
    }

    private func samples(_ values: [Double], spacing: TimeInterval = 900) -> [TimedHealthValue] {
        values.enumerated().map {
            TimedHealthValue(timestamp: wake.addingTimeInterval(Double($0.offset) * spacing), value: $0.element)
        }
    }
}
