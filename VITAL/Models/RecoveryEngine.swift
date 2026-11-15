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
