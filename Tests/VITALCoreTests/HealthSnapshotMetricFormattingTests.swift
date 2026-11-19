import XCTest
@testable import VITALCore

final class HealthSnapshotMetricFormattingTests: XCTestCase {
    func testRespiratoryRateUsesBreathsPerMinute() {
        var snapshot = HealthSnapshot.empty
        snapshot.respiratoryRate = 15.6
        XCTAssertEqual(snapshot.respiratoryRateText, "16 andetag/min")
    }

    func testBloodPressureFormatsPairedValues() {
        var snapshot = HealthSnapshot.empty
        snapshot.systolicBloodPressure = 122
        snapshot.diastolicBloodPressure = 78
        XCTAssertEqual(snapshot.bloodPressureText, "122/78")
    }

    func testBloodPressureRejectsInvalidOrIncompletePair() {
        var snapshot = HealthSnapshot.empty
        snapshot.systolicBloodPressure = 110
        XCTAssertEqual(snapshot.bloodPressureText, "—")
        snapshot.diastolicBloodPressure = 120
        XCTAssertEqual(snapshot.bloodPressureText, "—")
        snapshot.systolicBloodPressure = .nan
        snapshot.diastolicBloodPressure = 70
        XCTAssertEqual(snapshot.bloodPressureText, "—")
    }

    func testMissingOrInvalidValuesRemainUnavailable() {
        var snapshot = HealthSnapshot.empty
        XCTAssertEqual(snapshot.respiratoryRateText, "—")

        snapshot.respiratoryRate = .nan
        XCTAssertEqual(snapshot.respiratoryRateText, "—")
    }

    
    func testRespiratoryRateRejectsPhysiologicallyImplausibleValues() {
        var snapshot = HealthSnapshot.empty
        for value in [0.0, 100.1, Double.greatestFiniteMagnitude] {
            snapshot.respiratoryRate = value
            XCTAssertEqual(snapshot.respiratoryRateText, "—")
        }
    }

    func testOxygenSaturationFormatsAsPercentageAndRejectsInvalidValues() {
        var snapshot = HealthSnapshot.empty
        XCTAssertEqual(snapshot.oxygenSaturationText, "—")
        snapshot.oxygenSaturation = 98.2
        XCTAssertEqual(snapshot.oxygenSaturationText, "98 %")
        snapshot.oxygenSaturation = 0.98
        XCTAssertEqual(snapshot.oxygenSaturationText, "—")
        snapshot.oxygenSaturation = .nan
        XCTAssertEqual(snapshot.oxygenSaturationText, "—")
    }

    func testSleepingWristTemperatureIsDisplayedAsBaselineDeviation() {
        var snapshot = HealthSnapshot.empty
        XCTAssertEqual(snapshot.sleepingWristTemperatureText, "—")
        snapshot.sleepingWristTemperatureDeviationCelsius = 0.37
        XCTAssertTrue(snapshot.sleepingWristTemperatureText.hasPrefix("+"))
        XCTAssertTrue(snapshot.sleepingWristTemperatureText.hasSuffix(" °C"))
        snapshot.sleepingWristTemperatureDeviationCelsius = -0.24
        XCTAssertTrue(snapshot.sleepingWristTemperatureText.hasPrefix("-"))
        snapshot.sleepingWristTemperatureDeviationCelsius = 8
        XCTAssertEqual(snapshot.sleepingWristTemperatureText, "—")
    }

    func testNewActivityMetricsFormatWithExplicitUnits() {
        var snapshot = HealthSnapshot.empty
        snapshot.exerciseMinutes = 42
        snapshot.walkingRunningDistanceKM = 3.25
        snapshot.cyclingDistanceKM = 12.4
        snapshot.flightsClimbed = 8
        snapshot.walkingHeartRate = 102
        snapshot.vo2Max = 41.6
        snapshot.walkingSpeedMetersPerSecond = 1.24
        snapshot.walkingStepLengthCM = 72
        snapshot.walkingAsymmetryPercentage = 3.5

        XCTAssertEqual(snapshot.exerciseMinutesText, "42 min")
        XCTAssertTrue(snapshot.walkingRunningDistanceText.hasSuffix(" km"))
        XCTAssertTrue(snapshot.cyclingDistanceText.hasSuffix(" km"))
        XCTAssertEqual(snapshot.flightsClimbedText, "8 våningar")
        XCTAssertEqual(snapshot.walkingHeartRateText, "102 bpm")
        XCTAssertTrue(snapshot.vo2MaxText.hasSuffix(" ml/kg/min"))
        XCTAssertTrue(snapshot.walkingSpeedText.hasSuffix(" m/s"))
        XCTAssertEqual(snapshot.walkingStepLengthText, "72 cm")
        XCTAssertTrue(snapshot.walkingAsymmetryText.hasSuffix(" %"))
    }

    func testBodyCompositionMetricsRejectMissingAndImplausibleValues() {
        var snapshot = HealthSnapshot.empty
        XCTAssertEqual(snapshot.bodyFatText, "—")
        XCTAssertEqual(snapshot.leanBodyMassText, "—")
        snapshot.bodyFatPercentage = 22.5
        snapshot.leanBodyMassKG = 68.4
        XCTAssertTrue(snapshot.bodyFatText.hasSuffix(" %"))
        XCTAssertTrue(snapshot.leanBodyMassText.hasSuffix(" kg"))
        snapshot.bodyFatPercentage = 90
        snapshot.leanBodyMassKG = .infinity
        XCTAssertEqual(snapshot.bodyFatText, "—")
        XCTAssertEqual(snapshot.leanBodyMassText, "—")
    }

    func testCoreMetricsRejectNonFiniteAndOutOfRangeValues() {
        var snapshot = HealthSnapshot.empty
        snapshot.sleepDuration = .infinity
        snapshot.steps = .nan
        snapshot.restingHeartRate = .infinity
        snapshot.hrv = .nan
        XCTAssertEqual(snapshot.sleepText, "—")
        XCTAssertEqual(snapshot.stepsText, "—")
        XCTAssertEqual(snapshot.restingHeartRateText, "—")
        XCTAssertEqual(snapshot.hrvText, "—")

        snapshot.sleepDuration = -1
        snapshot.steps = -1
        snapshot.restingHeartRate = 0
        snapshot.hrv = 0
        XCTAssertEqual(snapshot.sleepText, "—")
        XCTAssertEqual(snapshot.stepsText, "—")
        XCTAssertEqual(snapshot.restingHeartRateText, "—")
        XCTAssertEqual(snapshot.hrvText, "—")
    }
    func testCoreMetricsRejectPhysiologicallyImplausibleValues() {
        var snapshot = HealthSnapshot.empty
        snapshot.sleepDuration = 25 * 3600
        snapshot.steps = 200_001
        snapshot.restingHeartRate = 240
        snapshot.hrv = 301
        XCTAssertEqual(snapshot.sleepText, "—")
        XCTAssertEqual(snapshot.stepsText, "—")
        XCTAssertEqual(snapshot.restingHeartRateText, "—")
        XCTAssertEqual(snapshot.hrvText, "—")
    }

    func testCoreMetricsAcceptValuesAtDefensiveBoundaries() {
        var snapshot = HealthSnapshot.empty
        snapshot.sleepDuration = 1800
        snapshot.steps = 200_000
        snapshot.restingHeartRate = 25
        snapshot.hrv = 1
        XCTAssertNotEqual(snapshot.sleepText, "—")
        XCTAssertNotEqual(snapshot.stepsText, "—")
        XCTAssertNotEqual(snapshot.restingHeartRateText, "—")
        XCTAssertNotEqual(snapshot.hrvText, "—")
    }

}
