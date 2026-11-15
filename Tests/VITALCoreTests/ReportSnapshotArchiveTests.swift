import XCTest
@testable import VITALCore

final class ReportSnapshotArchiveTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        return value
    }

    private func snapshot(
        kind: DailyReportKind = .morning,
        localDay: Date,
        capturedAt: Date,
        recoveryScore: Int?
    ) -> DailyReportSnapshot {
        DailyReportSnapshot(
            kind: kind,
            localDay: localDay,
            capturedAt: capturedAt,
            recoveryScore: recoveryScore,
            bodyBatteryScore: 72,
            sleepDurationSeconds: 7 * 3600,
            hrvMilliseconds: 48,
            restingHeartRateBPM: 54,
            steps: 1200,
            activeEnergyKcal: 340
        )
    }

    func testFirstSnapshotForDayAndKindIsStored() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        var archive = ReportSnapshotArchive()
        let candidate = snapshot(localDay: day, capturedAt: day, recoveryScore: 81)

        XCTAssertTrue(archive.appendIfAbsent(candidate, calendar: calendar))
        XCTAssertEqual(archive.snapshots, [candidate])
    }

    func testLaterHealthValuesCannotRewriteMorningSnapshot() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        var archive = ReportSnapshotArchive()
        let original = snapshot(localDay: day, capturedAt: day, recoveryScore: 81)
        let later = snapshot(localDay: day, capturedAt: day.addingTimeInterval(8 * 3600), recoveryScore: 42)

        XCTAssertTrue(archive.appendIfAbsent(original, calendar: calendar))
        XCTAssertFalse(archive.appendIfAbsent(later, calendar: calendar))
        XCTAssertEqual(archive.snapshot(for: day, kind: .morning, calendar: calendar), original)
        XCTAssertEqual(archive.snapshots.count, 1)
    }

    func testMorningAndEveningSnapshotsAreIndependent() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        var archive = ReportSnapshotArchive()
        let morning = snapshot(localDay: day, capturedAt: day, recoveryScore: 81)
        let evening = snapshot(kind: .evening, localDay: day,
                               capturedAt: day.addingTimeInterval(14 * 3600), recoveryScore: 81)

        XCTAssertTrue(archive.appendIfAbsent(morning, calendar: calendar))
        XCTAssertTrue(archive.appendIfAbsent(evening, calendar: calendar))
        XCTAssertEqual(archive.snapshots.count, 2)
    }

    func testNextLocalCalendarDayCanHaveItsOwnMorningSnapshot() {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        var archive = ReportSnapshotArchive()

        XCTAssertTrue(archive.appendIfAbsent(
            snapshot(localDay: day, capturedAt: day, recoveryScore: 81), calendar: calendar
        ))
        XCTAssertTrue(archive.appendIfAbsent(
            snapshot(localDay: nextDay, capturedAt: nextDay, recoveryScore: 76), calendar: calendar
        ))
        XCTAssertEqual(archive.snapshots.count, 2)
    }

    func testArchiveRoundTripsThroughCodable() throws {
        let day = calendar.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        var archive = ReportSnapshotArchive()
        XCTAssertTrue(archive.appendIfAbsent(
            snapshot(localDay: day, capturedAt: day, recoveryScore: nil), calendar: calendar
        ))

        let data = try JSONEncoder().encode(archive)
        let decoded = try JSONDecoder().decode(ReportSnapshotArchive.self, from: data)
        XCTAssertEqual(decoded, archive)
    }
}
