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

    func testRecoveryGuidanceIdentifiesPoorSleepAgainstPersonalBaseline() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 78, hrv: 96, restingPulse: 98)
        XCTAssertTrue(guidance.hasAttentionSignal)
        XCTAssertEqual(guidance.attentionSignals.count, 1)
        XCTAssertTrue(guidance.attentionSignals[0].contains("Sömnen"))
        XCTAssertTrue(guidance.recommendation.contains("sömnen"))
    }

    func testRecoveryGuidanceHighlightsMultipleSignals() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 78, hrv: 72, restingPulse: 80)
        XCTAssertEqual(guidance.attentionSignals.count, 3)
        XCTAssertTrue(guidance.title.contains("Flera"))
        XCTAssertTrue(guidance.recommendation.contains("lättare aktivitet"))
    }

    func testRecoveryGuidanceDoesNotInventAdviceWhenDataIsMissing() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 90, hrv: nil, restingPulse: 95)
        XCTAssertFalse(guidance.hasAttentionSignal)
        XCTAssertTrue(guidance.title.contains("Samlar"))
        XCTAssertTrue(guidance.attentionSignals.isEmpty)
    }

    func testRecoveryGuidanceTreatsThresholdAsInclusive() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 85, hrv: 85, restingPulse: 85)
        XCTAssertFalse(guidance.hasAttentionSignal)
        XCTAssertTrue(guidance.title.contains("Inga"))
    }

    func testRecoveryGuidanceRejectsNonFiniteComponentsAsMissing() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 90, hrv: .nan, restingPulse: 95)
        XCTAssertFalse(guidance.hasAttentionSignal)
        XCTAssertTrue(guidance.title.contains("Samlar"))
        XCTAssertTrue(guidance.attentionSignals.isEmpty)
    }

    func testRecoveryGuidanceIsNeutralWhenSignalsAreNearBaseline() {
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: 90, hrv: 92, restingPulse: 94)
        XCTAssertFalse(guidance.hasAttentionSignal)
        XCTAssertTrue(guidance.title.contains("Inga"))
    }

    func testImplausibleInputsDoNotProduceRecoveryScore() {
        let cases: [RecoveryInputs] = [
            .init(sleepDurationHours: 30, baselineSleepHours: 8,
                  hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
                  restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
                  baselineDaysAvailable: 30),
            .init(sleepDurationHours: 8, baselineSleepHours: 8,
                  hrvMilliseconds: 500, baselineHRVMilliseconds: 50,
                  restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
                  baselineDaysAvailable: 30),
            .init(sleepDurationHours: 8, baselineSleepHours: 8,
                  hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
                  restingHeartRateBPM: 10, baselineRestingHeartRateBPM: 60,
                  baselineDaysAvailable: 30),
            .init(sleepDurationHours: 8, baselineSleepHours: 30,
                  hrvMilliseconds: 50, baselineHRVMilliseconds: 50,
                  restingHeartRateBPM: 60, baselineRestingHeartRateBPM: 60,
                  baselineDaysAvailable: 30)
        ]

        for input in cases {
            let result = RecoveryEngine.calculate(input)
            XCTAssertNil(result.score)
            XCTAssertTrue(result.isBaselineReady)
            XCTAssertTrue(result.explanation.contains("saknas"))
        }
    }

}
