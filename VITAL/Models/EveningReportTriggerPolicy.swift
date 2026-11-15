import Foundation

struct EveningReportTriggerDecision: Equatable {
    let shouldCreateSnapshot: Bool
    let reason: String
}

/// The evening report uses a local clock threshold. iOS execution is not
/// guaranteed at the exact minute, so the snapshot is captured on the first
/// successful refresh at or after the configured time.
enum EveningReportTriggerPolicy {
    static let defaultHour = 21

    static func evaluate(
        eventDate: Date,
        reportDay: Date,
        hour: Int = defaultHour,
        calendar: Calendar = .current
    ) -> EveningReportTriggerDecision {
        guard (0...23).contains(hour) else {
            return EveningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Ogiltig lokal rapporttid."
            )
        }
        guard calendar.isDate(eventDate, inSameDayAs: reportDay) else {
            return EveningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Händelsen tillhör inte den aktuella rapportdagen."
            )
        }
        let eventHour = calendar.component(.hour, from: eventDate)
        guard eventHour >= hour else {
            return EveningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Kvällsrapporten väntar till kl. \(String(format: "%02d", hour))."
            )
        }
        return EveningReportTriggerDecision(
            shouldCreateSnapshot: true,
            reason: "Kvällsrapportens lokala tid har passerat."
        )
    }
}
