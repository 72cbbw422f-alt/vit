import XCTest
@testable import VITALCore

final class HealthSnapshotMetricFormattingTests: XCTestCase {
    func testRespiratoryRateUsesBreathsPerMinute() {
        var snapshot = HealthSnapshot.empty
        snapshot.respiratoryRate = 15.6
        XCTAssertEqual(snapshot.respiratoryRateText, "16 andetag/min")
    }

    func testOxygenSaturationConvertsHealthKitFractionToPercent() {
        var snapshot = HealthSnapshot.empty
        snapshot.oxygenSaturation = 0.975
        XCTAssertEqual(snapshot.oxygenSaturationText, "98 %")
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
        XCTAssertEqual(snapshot.oxygenSaturationText, "—")

        snapshot.respiratoryRate = .nan
        snapshot.oxygenSaturation = 1.5
        XCTAssertEqual(snapshot.respiratoryRateText, "—")
        XCTAssertEqual(snapshot.oxygenSaturationText, "—")
    }
}
