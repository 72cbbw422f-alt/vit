import Foundation

/// Transparent, deterministic estimate of overnight recovery.
/// This is a wellness estimate, not a medical measurement or diagnosis.
struct RecoveryInputs {
    let sleepDurationHours: Double?
    let baselineSleepHours: Double?
    let hrvMilliseconds: Double?
    let baselineHRVMilliseconds: Double?
    let restingHeartRateBPM: Double?
    let baselineRestingHeartRateBPM: Double?
    let baselineDaysAvailable: Int
}

struct RecoveryResult {
    let score: Int?
    let sleepComponent: Double?
    let hrvComponent: Double?
    let restingPulseComponent: Double?
    let explanation: String
    let isBaselineReady: Bool
}

enum RecoveryEngine {
    static let requiredBaselineDays = 14

    /// Returns nil score until each input has valid values and a sufficiently populated
    /// personal baseline. Baselines are expected to be calculated from the prior 30 days.
    static func calculate(_ input: RecoveryInputs) -> RecoveryResult {
        guard input.baselineDaysAvailable >= requiredBaselineDays else {
            return RecoveryResult(score: nil, sleepComponent: nil, hrvComponent: nil,
                restingPulseComponent: nil,
                explanation: "Samlar personlig baslinje. Minst 14 giltiga dagar behövs.",
                isBaselineReady: false)
        }

        guard let sleep = positive(input.sleepDurationHours),
              let sleepBaseline = positive(input.baselineSleepHours),
              let hrv = positive(input.hrvMilliseconds),
              let hrvBaseline = positive(input.baselineHRVMilliseconds),
              let pulse = positive(input.restingHeartRateBPM),
              let pulseBaseline = positive(input.baselineRestingHeartRateBPM) else {
            return RecoveryResult(score: nil, sleepComponent: nil, hrvComponent: nil,
                restingPulseComponent: nil,
                explanation: "Återhämtning kan inte beräknas: ett eller flera mätvärden saknas.",
                isBaselineReady: true)
        }

        // Components are bounded to avoid a single unusual reading dominating the estimate.
        let sleepScore = clamp((sleep / sleepBaseline) * 100, lower: 0, upper: 100)
        let hrvScore = clamp(100 + ((hrv / hrvBaseline) - 1) * 100, lower: 0, upper: 100)
        let pulseScore = clamp(100 - ((pulse - pulseBaseline) * 5), lower: 0, upper: 100)

        // Fixed weights sum to 1.0. Keep visible in documentation and tests.
        let weighted = sleepScore * 0.40 + hrvScore * 0.35 + pulseScore * 0.25
        return RecoveryResult(score: Int(weighted.rounded()),
            sleepComponent: sleepScore, hrvComponent: hrvScore,
            restingPulseComponent: pulseScore,
            explanation: "Uppskattning baserad på sömn, HRV och vilopuls jämfört med din personliga 30-dagarsbaslinje.",
            isBaselineReady: true)
    }

    private static func positive(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return value
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}


/// Converts captured recovery components into cautious, explainable wellness guidance.
/// The threshold is a product heuristic, not a clinical cutoff.
struct RecoveryGuidance {
    let title: String
    let detail: String
    let recommendation: String
    let attentionSignals: [String]
    let hasAttentionSignal: Bool
}

enum RecoveryGuidancePolicy {
    static let attentionThreshold = 85.0

    static func evaluate(sleep: Double?, hrv: Double?, restingPulse: Double?) -> RecoveryGuidance {
        guard let sleep, let hrv, let restingPulse,
              sleep.isFinite, hrv.isFinite, restingPulse.isFinite else {
            return RecoveryGuidance(
                title: "Samlar nattens värden",
                detail: "VITAL saknar tillräckligt underlag för att jämföra alla återhämtningssignaler med din personliga baslinje.",
                recommendation: "Följ dagsformen och invänta mer hälsodata innan återhämtningen bedöms.",
                attentionSignals: [],
                hasAttentionSignal: false
            )
        }

        var signals: [String] = []
        if sleep < attentionThreshold { signals.append("Sömnen var kortare än din personliga normalnivå.") }
        if hrv < attentionThreshold { signals.append("HRV låg under din personliga baslinje.") }
        if restingPulse < attentionThreshold { signals.append("Vilopulsen låg över din personliga baslinje.") }

        guard !signals.isEmpty else {
            return RecoveryGuidance(
                title: "Inga tydliga avvikelser",
                detail: "De tre nattliga signalerna ligger nära eller över dina personliga referensnivåer.",
                recommendation: "Fortsätt enligt din vanliga plan och anpassa dagen efter hur du känner dig.",
                attentionSignals: [],
                hasAttentionSignal: false
            )
        }

        let recommendation: String
        if signals.count >= 2 {
            recommendation = "Flera signaler avviker samtidigt. Överväg lättare aktivitet och prioritera återhämtning."
        } else if sleep < attentionThreshold {
            recommendation = "Prioritera en lugnare start och ge sömnen extra utrymme kommande natt."
        } else if hrv < attentionThreshold {
            recommendation = "Var uppmärksam på dagsformen och undvik att öka träningsintensiteten i onödan."
        } else {
            recommendation = "Håll koll på dagsformen och välj lättare aktivitet om kroppen känns belastad."
        }

        return RecoveryGuidance(
            title: signals.count >= 2 ? "Flera signaler att uppmärksamma" : "En signal att uppmärksamma",
            detail: signals.joined(separator: " "),
            recommendation: recommendation,
            attentionSignals: signals,
            hasAttentionSignal: true
        )
    }
}
