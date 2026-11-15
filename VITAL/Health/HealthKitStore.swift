import Foundation
import Combine
import HealthKit

@MainActor
final class HealthKitStore: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationRequested = false
    @Published private(set) var lastError: String?
    @Published private(set) var morningReport: DailyReportSnapshot?
    @Published private(set) var reportHistory: [DailyReportSnapshot] = []
    private let store = HKHealthStore()
    private let baselineCalendar = Calendar.current
    private var sleepObserverQuery: HKObserverQuery?
    private let reportArchiveKey = "vital.dailyReportArchive.v1"
    private var reportArchive = ReportSnapshotArchive()

    func requestAccessAndRefresh() async {
        guard isAvailable else {
            lastError = "Apple Hälsa är inte tillgängligt på den här enheten."
            return
        }
        guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let resting = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
              let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            lastError = "Kunde inte läsa in alla hälsodatatyper."
            return
        }
        loadReportArchive()
        do {
            try await store.requestAuthorization(toShare: [], read: [sleep, resting, hrv, heartRate, steps, energy, weight])
            authorizationRequested = true
            await startSleepObservation()
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }


    /// Observe sleep-analysis changes and request background delivery.
    /// The observer is a data-change signal, not a direct Sleep Focus listener.
    private func startSleepObservation() async {
        guard sleepObserverQuery == nil,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completion, error in
            guard error == nil else {
                completion()
                return
            }
            Task { @MainActor [weak self] in
                await self?.refresh()
                completion()
            }
        }
        sleepObserverQuery = query
        store.execute(query)

        await withCheckedContinuation { continuation in
            store.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { _, _ in
                continuation.resume()
            }
        }
    }

    func refresh() async {
        let now = Date()
        async let sleepSessionValue = latestSleepSession()
        async let overnightHRVSamples = recentTimedQuantitySamples(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let overnightPulseSamples = recentTimedQuantitySamples(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let bodyBatteryHeartRateSamples = recentTimedQuantitySamples(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let bodyBatteryEnergySamples = recentTimedQuantitySamples(.activeEnergyBurned, unit: .kilocalorie())
        async let restingValue = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrvValue = latestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let stepsValue = todaySum(.stepCount, unit: .count())
        async let energyValue = todaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let weightValue = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let baselines = loadPersonalBaselines(asOf: now)

        let baselineValues = await baselines
        let sleepSession = await sleepSessionValue
        let overnightMetrics: OvernightMetrics
        if let sleepSession {
            overnightMetrics = OvernightMetricSelector.select(
                hrv: await overnightHRVSamples,
                restingHeartRate: await overnightPulseSamples,
                sleepSession: sleepSession
            )
        } else {
            overnightMetrics = OvernightMetrics(
                hrvMilliseconds: nil,
                restingHeartRateBPM: nil,
                hrvSampleCount: 0,
                restingHeartRateSampleCount: 0
            )
        }
        var updatedSnapshot = HealthSnapshot(
            sleepDuration: sleepSession?.duration,
            restingHeartRate: await restingValue,
            hrv: await hrvValue,
            overnightHRV: overnightMetrics.hrvMilliseconds,
            overnightRestingHeartRate: overnightMetrics.restingHeartRateBPM,
            steps: await stepsValue,
            activeEnergy: await energyValue,
            latestWeight: await weightValue,
            restingHeartRateBaseline: baselineValues.resting,
            hrvBaseline: baselineValues.hrv,
            sleepBaseline: baselineValues.sleep,
            lastUpdated: now
        )
        if let wakeTime = sleepSession?.end {
            updatedSnapshot.bodyBattery = BodyBatteryEngine.calculate(BodyBatteryInputs(
                wakeTime: wakeTime,
                asOf: now,
                overnightRecoveryScore: updatedSnapshot.recoveryResult.score,
                restingHeartRateBaselineBPM: baselineValues.resting.median,
                heartRateSamples: await bodyBatteryHeartRateSamples,
                activeEnergySamples: await bodyBatteryEnergySamples
            ))
        }
        snapshot = updatedSnapshot
        createMorningReportIfEligible(from: updatedSnapshot, sleepSession: sleepSession, capturedAt: now)
    }


    /// Restore frozen report history from local storage.
    private func loadReportArchive() {
        guard let data = UserDefaults.standard.data(forKey: reportArchiveKey),
              let decoded = try? JSONDecoder().decode(ReportSnapshotArchive.self, from: data) else { return }
        reportArchive = decoded
        reportHistory = decoded.snapshots.reversed()
        morningReport = decoded.snapshot(for: Date(), kind: .morning)
    }

    /// Freeze the first eligible morning snapshot for the local wake-up day.
    /// Missing measurements remain nil; subsequent HealthKit refreshes cannot rewrite it.
    private func createMorningReportIfEligible(
        from healthSnapshot: HealthSnapshot,
        sleepSession: SleepSession?,
        capturedAt: Date
    ) {
        let calendar = Calendar.current
        let decision = MorningReportTriggerPolicy.evaluate(
            source: .healthKitSleepUpdated,
            eventDate: capturedAt,
            mainSleep: sleepSession,
            reportDay: capturedAt,
            calendar: calendar
        )
        guard decision.shouldCreateSnapshot else { return }
        guard let sleepSession else { return }
        let day = calendar.startOfDay(for: sleepSession.end)
        let candidate = DailyReportSnapshot(
            kind: .morning,
            localDay: day,
            capturedAt: capturedAt,
            recoveryScore: healthSnapshot.recoveryResult.score,
            bodyBatteryScore: healthSnapshot.bodyBattery?.score,
            sleepDurationSeconds: healthSnapshot.sleepDuration,
            hrvMilliseconds: healthSnapshot.overnightHRV,
            restingHeartRateBPM: healthSnapshot.overnightRestingHeartRate,
            steps: healthSnapshot.steps,
            activeEnergyKcal: healthSnapshot.activeEnergy
        )
        guard reportArchive.appendIfAbsent(candidate, calendar: calendar),
              let data = try? JSONEncoder().encode(reportArchive) else { return }
        UserDefaults.standard.set(data, forKey: reportArchiveKey)
        reportHistory = reportArchive.snapshots.reversed()
        morningReport = candidate
    }

    private func loadPersonalBaselines(asOf date: Date) async -> (resting: PersonalBaseline, hrv: PersonalBaseline, sleep: PersonalBaseline) {
        let today = baselineCalendar.startOfDay(for: date)
        let start = baselineCalendar.date(byAdding: .day, value: -30, to: today) ?? today
        let end = today

        async let restingSamples = historicalQuantitySamples(
            .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            start: start,
            end: end
        )
        async let hrvSamples = historicalQuantitySamples(
            .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            start: start,
            end: end
        )
        async let sleepSamples = historicalSleepSessions(start: start, end: end)

        let resting = await restingSamples
        let hrv = await hrvSamples
        let sleep = await sleepSamples
        return (
            PersonalBaselineCalculator.calculate(samples: resting, windowStart: start, windowEnd: end),
            PersonalBaselineCalculator.calculate(samples: hrv, windowStart: start, windowEnd: end),
            PersonalBaselineCalculator.calculate(samples: sleep, windowStart: start, windowEnd: end)
        )
    }

    private func historicalQuantitySamples(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> [DailyBaselineSample] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, _ in
                    let values = ((samples as? [HKQuantitySample]) ?? []).map {
                        DailyBaselineSample(day: $0.endDate, value: $0.quantity.doubleValue(for: unit))
                    }
                    continuation.resume(returning: values)
                }
            store.execute(query)
        }
    }

    private func historicalSleepSessions(start: Date, end: Date) async -> [DailyBaselineSample] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                    let asleepValues = [
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ]
                    let intervals = ((samples as? [HKCategorySample]) ?? [])
                        .filter { asleepValues.contains($0.value) }
                        .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                    let sessions = SleepSessionCalculator.sessions(intervals: intervals)
                    // One representative sleep session per local wake-up date. If there are
                    // multiple sessions that day, retain the longest; naps are not summed.
                    let byDay = Dictionary(grouping: sessions) {
                        Calendar.current.startOfDay(for: $0.end)
                    }
                    let daily = byDay.compactMap { day, sessions -> DailyBaselineSample? in
                        guard let longest = sessions.max(by: { $0.duration < $1.duration }) else { return nil }
                        return DailyBaselineSample(day: day, value: longest.duration / 3600)
                    }
                    continuation.resume(returning: daily)
                }
            store.execute(query)
        }
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                    continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
                }
            store.execute(query)
        }
    }

    private func todaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func recentTimedQuantitySamples(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> [TimedHealthValue] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -36, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, _ in
                    let values = ((samples as? [HKQuantitySample]) ?? []).map {
                        TimedHealthValue(timestamp: $0.endDate, value: $0.quantity.doubleValue(for: unit), startTimestamp: $0.startDate)
                    }
                    continuation.resume(returning: values)
                }
            store.execute(query)
        }
    }

    private func latestSleepSession() async -> SleepSession? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -36, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                    let asleepValues = [
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ]
                    let intervals = ((samples as? [HKCategorySample]) ?? [])
                        .filter { asleepValues.contains($0.value) }
                        .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                    continuation.resume(returning: SleepSessionCalculator.primarySession(intervals: intervals))
                }
            store.execute(query)
        }
    }
}
