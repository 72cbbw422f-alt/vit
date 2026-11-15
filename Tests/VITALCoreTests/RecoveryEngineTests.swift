import XCTest
@testable import VITALCore

final class RecoveryEngineTests: XCTestCase {
    func testBaselineMustBeSufficient() {
        let result = RecoveryEngine.calculate(.init(
            sleepDurationHours: 8, baselineSleepHours: 8,
            hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
            restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
            baselineDaysAvailable: 13
        ))
        XCTAssertNil(result.score)
        XCTAssertFalse(result.isBaselineReady)
    }

    func testIdenticalToPersonalBaselineProducesHundred() {
        let result = RecoveryEngine.calculate(.init(
            sleepDurationHours: 8, baselineSleepHours: 8,
            hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
            restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
            baselineDaysAvailable: 30
        ))
        XCTAssertEqual(result.score, 100)
        XCTAssertTrue(result.isBaselineReady)
    }

    func testMissingMeasurementDoesNotInventScore() {
        let result = RecoveryEngine.calculate(.init(
            sleepDurationHours: nil, baselineSleepHours: 8,
            hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
            restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
            baselineDaysAvailable: 30
        ))
        XCTAssertNil(result.score)
        XCTAssertTrue(result.isBaselineReady)
        XCTAssertTrue(result.explanation.contains("saknas"))
    }

    func testWorseSleepHRVAndRestingPulseReduceScore() {
        let result = RecoveryEngine.calculate(.init(
            sleepDurationHours: 6, baselineSleepHours: 8,
            hrvMilliseconds: 35, baselineHRVMilliseconds: 50,
            restingHeartRateBPM: 65, baselineRestingHeartRateBPM: 60,
            baselineDaysAvailable: 30
        ))
        XCTAssertNotNil(result.score)
        XCTAssertLessThan(result.score!, 100)
    }

    func testComponentsAreBounded() {
        let result = RecoveryEngine.calculate(.init(
            sleepDurationHours: 20, baselineSleepHours: 7,
            hrvMilliseconds: 200, baselineHRVMilliseconds: 40,
            restingHeartRateBPM: 30, baselineRestingHeartRateBPM: 80,
            baselineDaysAvailable: 30
        ))
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.sleepComponent, 100)
        XCTAssertEqual(result.hrvComponent, 100)
        XCTAssertEqual(result.restingPulseComponent, 100)
    }
}
