import Foundation

enum MorningReportTriggerSource: String, Codable {
    case sleepFocusEnded
    case healthKitSleepUpdated
    case appBecameActive
}

struct MorningReportTriggerDecision: Equatable {
    let shouldCreateSnapshot: Bool
    let reason: String
}

/// Determines whether an observed event is a credible wake-up trigger.
/// A short settling interval gives HealthKit time to deliver additional
/// overnight samples before the immutable report is captured.
enum MorningReportTriggerPolicy {
    static let minimumMainSleepDuration: TimeInterval = 3 * 60 * 60
    static let maximumWakeAge: TimeInterval = 18 * 60 * 60
    static let minimumDataSettlingInterval: TimeInterval = 20 * 60

    static func evaluate(
        source: MorningReportTriggerSource,
        eventDate: Date,
        mainSleep: SleepSession?,
        reportDay: Date,
        calendar: Calendar = .current
    ) -> MorningReportTriggerDecision {
        guard let mainSleep else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Väntar på en registrerad huvudsömn."
            )
        }
        guard mainSleep.end <= eventDate else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Sömnperioden är inte avslutad ännu."
            )
        }
        guard mainSleep.duration >= minimumMainSleepDuration else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Sömnperioden är för kort för att räknas som huvudsömn."
            )
        }
        guard eventDate.timeIntervalSince(mainSleep.end) <= maximumWakeAge,
              eventDate >= mainSleep.end else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Uppvaknandet ligger utanför rapportens giltiga tidsfönster."
            )
        }
        guard eventDate.timeIntervalSince(mainSleep.end) >= minimumDataSettlingInterval else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Väntar 20 minuter efter uppvaknandet så att nattdata hinner synkroniseras."
            )
        }
        guard calendar.isDate(mainSleep.end, inSameDayAs: reportDay) else {
            return MorningReportTriggerDecision(
                shouldCreateSnapshot: false,
                reason: "Sömnperiodens uppvakningsdag matchar inte rapportdagen."
            )
        }

        let triggerDescription: String
        switch source {
        case .sleepFocusEnded:
            triggerDescription = "Sömnfokus avslutades"
        case .healthKitSleepUpdated:
            triggerDescription = "Apple Hälsa registrerade en sömnuppdatering"
        case .appBecameActive:
            triggerDescription = "VITAL öppnades efter sömnen"
        }
        return MorningReportTriggerDecision(
            shouldCreateSnapshot: true,
            reason: "(triggerDescription); huvudsömnen är avslutad och datans väntetid har passerat."
        )
    }
}
