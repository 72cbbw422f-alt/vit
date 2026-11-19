import Foundation
import Combine
import HealthKit

struct HealthTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct BloodPressureTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let systolic: Double
    let diastolic: Double
}

struct HealthDataDiagnostic: Identifiable {
    let title: String
    let sampleCount: Int
    let latestDate: Date?
    let errorMessage: String?

    init(title: String, sampleCount: Int, latestDate: Date?, errorMessage: String? = nil) {
        self.title = title
        self.sampleCount = sampleCount
        self.latestDate = latestDate
        self.errorMessage = errorMessage
    }

    var id: String { title }
    var statusText: String {
        if errorMessage != nil { return "Kunde inte läsa" }
        return sampleCount == 0 ? "Inga mätningar hittades" : "\(sampleCount) mätningar"
    }
}

@MainActor
final class HealthKitStore: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty
    @Published private(set) var weightHistory: [HealthTrendPoint] = []
    @Published private(set) var hrvHistory: [HealthTrendPoint] = []
    @Published private(set) var restingHeartRateHistory: [HealthTrendPoint] = []
    @Published private(set) var bloodPressureHistory: [BloodPressureTrendPoint] = []
    @Published private(set) var dataDiagnostics: [HealthDataDiagnostic] = []
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationRequested = false
    @Published private(set) var backgroundSleepDeliveryEnabled = false
    @Published private(set) var lastError: String?
    @Published private(set) var morningReport: DailyReportSnapshot?
    @Published private(set) var reportHistory: [DailyReportSnapshot] = []
    private let store = HKHealthStore()
    private let baselineCalendar = Calendar.current
    private var sleepObserverQuery: HKObserverQuery?
    private let reportArchiveKey = "vital.dailyReportArchive.v1"
    private var reportArchive = ReportSnapshotArchive()
    @Published private(set) var isRefreshing = false
    private var refreshRequestedAgain = false

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
            lastError = "Kunde inte läsa in grundläggande hälsodatatyper."
            return
        }
        // Optional metrics must never prevent access to core sleep and activity data.
        var readTypes: Set<HKObjectType> = [sleep, resting, hrv, heartRate, steps, energy, weight]
        // Expand read access to common Apple Health metrics used for activity,
        // cardiovascular trends and body composition. Unsupported types are skipped.
        let additionalIdentifiers: [HKQuantityTypeIdentifier] = [
            .appleExerciseTime, .distanceWalkingRunning, .distanceCycling,
            .flightsClimbed, .walkingHeartRateAverage, .vo2Max,
            .bodyFatPercentage, .leanBodyMass, .walkingSpeed,
            .walkingStepLength, .walkingAsymmetryPercentage
        ]
        for identifier in additionalIdentifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                readTypes.insert(type)
            }
        }
        let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)
        let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)
        // Blood pressure correlations are queried as a paired sample below,
        // but iOS rejects the correlation type in requestAuthorization(read:).
        // Request read access for the systolic and diastolic quantity types only.
        if let systolicType { readTypes.insert(systolicType) }
        if let diastolicType { readTypes.insert(diastolicType) }
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            readTypes.insert(respiratoryRate)
        }
        if let wristTemperature = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) {
            readTypes.insert(wristTemperature)
        }
        loadReportArchive()
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
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
            if let error {
                Task { @MainActor [weak self] in
                    self?.recordQueryError(error, context: "Sömnsynk i bakgrunden")
                    completion()
                }
                return
            }
            Task { @MainActor [weak self] in
                await self?.refresh()
                completion()
            }
        }
        sleepObserverQuery = query
        store.execute(query)

        store.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { [weak self] success, error in
            Task { @MainActor [weak self] in
                self?.backgroundSleepDeliveryEnabled = success
                if let error {
                    self?.recordQueryError(error, context: "Bakgrundsuppdatering av sömndata")
                } else if !success {
                    self?.recordStatusMessage("Apple Hälsa bekräftade inte bakgrundsuppdatering av sömndata.")
                }
            }
        }
    }

    func refresh() async {
        // Coalesce overlapping foreground/background refresh requests into one follow-up pass.
        guard !isRefreshing else {
            refreshRequestedAgain = true
            return
        }
        isRefreshing = true
        lastError = nil
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
        async let weightSample = latestQuantitySample(.bodyMass, unit: .gramUnit(with: .kilo))
        async let bloodPressureSample = latestBloodPressureSample()
        async let historicalWeight = historicalWeightSamples()
        async let historicalHRV = historicalQuantitySamples(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), context: "HRV-historik")
        async let historicalRestingHeartRate = historicalQuantitySamples(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), context: "Vilopulshistorik")
        async let historicalBloodPressure = historicalBloodPressureSamples()
        async let respiratoryRateSample = latestQuantitySample(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let wristTemperatureSample = latestQuantitySample(.appleSleepingWristTemperature, unit: .degreeCelsius())
        async let exerciseMinutesValue = todaySum(.appleExerciseTime, unit: .minute())
        async let walkingDistanceValue = todaySum(.distanceWalkingRunning, unit: HKUnit.meterUnit(with: .kilo))
        async let cyclingDistanceValue = todaySum(.distanceCycling, unit: HKUnit.meterUnit(with: .kilo))
        async let flightsClimbedValue = todaySum(.flightsClimbed, unit: .count())
        async let walkingHeartRateSample = latestQuantitySample(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()))
        async let vo2MaxSample = latestQuantitySample(.vo2Max, unit: HKUnit(from: "mL/kg*min"))
        async let bodyFatSample = latestQuantitySample(.bodyFatPercentage, unit: .percent())
        async let leanBodyMassSample = latestQuantitySample(.leanBodyMass, unit: .gramUnit(with: .kilo))
        async let walkingSpeedSample = latestQuantitySample(.walkingSpeed, unit: HKUnit.meter().unitDivided(by: .second()))
        async let walkingStepLengthSample = latestQuantitySample(.walkingStepLength, unit: HKUnit.meterUnit(with: .centi))
        async let walkingAsymmetrySample = latestQuantitySample(.walkingAsymmetryPercentage, unit: .percent())
        async let diagnostics = loadDataDiagnostics()
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
            latestWeight: await weightSample?.value,
            latestWeightDate: await weightSample?.date,
            systolicBloodPressure: await bloodPressureSample?.systolic,
            diastolicBloodPressure: await bloodPressureSample?.diastolic,
            bloodPressureDate: await bloodPressureSample?.date,
            respiratoryRate: await respiratoryRateSample?.value,
            respiratoryRateDate: await respiratoryRateSample?.date,
            sleepingWristTemperatureDeviationCelsius: await wristTemperatureSample?.value,
            sleepingWristTemperatureDate: await wristTemperatureSample?.date,
            exerciseMinutes: await exerciseMinutesValue,
            walkingRunningDistanceKM: await walkingDistanceValue,
            cyclingDistanceKM: await cyclingDistanceValue,
            flightsClimbed: await flightsClimbedValue,
            walkingHeartRate: await walkingHeartRateSample?.value,
            walkingHeartRateDate: await walkingHeartRateSample?.date,
            vo2Max: await vo2MaxSample?.value,
            vo2MaxDate: await vo2MaxSample?.date,
            bodyFatPercentage: await bodyFatSample?.value,
            bodyFatDate: await bodyFatSample?.date,
            leanBodyMassKG: await leanBodyMassSample?.value,
            leanBodyMassDate: await leanBodyMassSample?.date,
            walkingSpeedMetersPerSecond: await walkingSpeedSample?.value,
            walkingSpeedDate: await walkingSpeedSample?.date,
            walkingStepLengthCM: await walkingStepLengthSample?.value,
            walkingStepLengthDate: await walkingStepLengthSample?.date,
            walkingAsymmetryPercentage: await walkingAsymmetrySample?.value,
            walkingAsymmetryDate: await walkingAsymmetrySample?.date,
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
        weightHistory = await historicalWeight
        hrvHistory = await historicalHRV
        restingHeartRateHistory = await historicalRestingHeartRate
        bloodPressureHistory = await historicalBloodPressure
        dataDiagnostics = await diagnostics
        // New scheduled morning/evening reports are intentionally disabled.
        // Previously saved report history remains available and is loaded unchanged.
        isRefreshing = false
        if refreshRequestedAgain {
            refreshRequestedAgain = false
            await refresh()
        }
    }


    /// Restore frozen report history from local storage.
    private func loadReportArchive() {
        guard let data = UserDefaults.standard.data(forKey: reportArchiveKey),
              let decoded = try? JSONDecoder().decode(ReportSnapshotArchive.self, from: data) else { return }
        reportArchive = decoded
        reportHistory = Array(decoded.snapshots.reversed())
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
        let recovery = healthSnapshot.recoveryResult
        let candidate = DailyReportSnapshot(
            kind: .morning,
            localDay: day,
            capturedAt: capturedAt,
            recoveryScore: recovery.score,
            sleepComponentScore: recovery.sleepComponent,
            hrvComponentScore: recovery.hrvComponent,
            restingPulseComponentScore: recovery.restingPulseComponent,
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
        reportHistory = Array(reportArchive.snapshots.reversed())
        morningReport = candidate
    }

    /// Freeze the first evening snapshot after the local 21:00 threshold.
    /// The current-day activity and body-battery values are captured once and
    /// later HealthKit refreshes cannot rewrite the archived report.
    private func createEveningReportIfEligible(
        from healthSnapshot: HealthSnapshot,
        capturedAt: Date
    ) {
        let calendar = Calendar.current
        let decision = EveningReportTriggerPolicy.evaluate(
            eventDate: capturedAt,
            reportDay: capturedAt,
            calendar: calendar
        )
        guard decision.shouldCreateSnapshot else { return }
        let day = calendar.startOfDay(for: capturedAt)
        let candidate = DailyReportSnapshot(
            kind: .evening,
            localDay: day,
            capturedAt: capturedAt,
            // Evening reporting is based on daytime load/body battery, not
            // the overnight recovery score already used by the morning report.
            recoveryScore: nil,
            sleepComponentScore: nil,
            hrvComponentScore: nil,
            restingPulseComponentScore: nil,
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
        reportHistory = Array(reportArchive.snapshots.reversed())
    }

    /// Counts recent samples per HealthKit type so an empty UI value can be
    /// investigated instead of silently appearing as a dash.
    private func loadDataDiagnostics() async -> [HealthDataDiagnostic] {
        let definitions: [(String, HKSampleType?)] = [
            ("Sömn", HKObjectType.categoryType(forIdentifier: .sleepAnalysis)),
            ("Steg", HKObjectType.quantityType(forIdentifier: .stepCount)),
            ("Aktiv energi", HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)),
            ("Vilopuls", HKObjectType.quantityType(forIdentifier: .restingHeartRate)),
            ("Puls", HKObjectType.quantityType(forIdentifier: .heartRate)),
            ("HRV", HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)),
            ("Vikt", HKObjectType.quantityType(forIdentifier: .bodyMass)),
            ("Blodtryck", HKObjectType.correlationType(forIdentifier: .bloodPressure)),
            ("Andningsfrekvens", HKObjectType.quantityType(forIdentifier: .respiratoryRate)),
            ("Handledstemperatur", HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature)),
            ("Träningstid", HKObjectType.quantityType(forIdentifier: .appleExerciseTime)),
            ("Gång- och löpdistans", HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)),
            ("Cykeldistans", HKObjectType.quantityType(forIdentifier: .distanceCycling)),
            ("Trappor", HKObjectType.quantityType(forIdentifier: .flightsClimbed)),
            ("Gångpuls", HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)),
            ("VO₂ max", HKObjectType.quantityType(forIdentifier: .vo2Max)),
            ("Kroppsfett", HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)),
            ("Muskelmassa", HKObjectType.quantityType(forIdentifier: .leanBodyMass)),
            ("Gånghastighet", HKObjectType.quantityType(forIdentifier: .walkingSpeed)),
            ("Steglängd", HKObjectType.quantityType(forIdentifier: .walkingStepLength)),
            ("Gångasymmetri", HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage))
        ]
        var results: [HealthDataDiagnostic] = []
        for (title, type) in definitions {
            guard let type else {
                results.append(HealthDataDiagnostic(title: title, sampleCount: 0, latestDate: nil, errorMessage: "Datatypen stöds inte av den här iOS-versionen."))
                continue
            }
            results.append(await countRecentSamples(title: title, type: type))
        }
        return results.sorted { $0.title < $1.title }
    }

    private func countRecentSamples(title: String, type: HKSampleType) async -> HealthDataDiagnostic {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                    if let error {
                        continuation.resume(returning: HealthDataDiagnostic(title: title, sampleCount: 0, latestDate: nil, errorMessage: error.localizedDescription))
                        return
                    }
                    let values = samples ?? []
                    continuation.resume(returning: HealthDataDiagnostic(
                        title: title,
                        sampleCount: values.count,
                        latestDate: values.first?.endDate
                    ))
                }
            store.execute(query)
        }
    }

    private func recordQueryError(_ error: Error, context: String) {
        let message = "\(context): \(error.localizedDescription)"
        if let existing = lastError, !existing.contains(message) {
            lastError = existing + "\n" + message
        } else {
            lastError = message
        }
    }

    private func recordStatusMessage(_ message: String) {
        if let existing = lastError, !existing.contains(message) {
            lastError = existing + "\n" + message
        } else {
            lastError = message
        }
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
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in
                            self?.recordQueryError(error, context: "Historisk hälsodata")
                        }
                        continuation.resume(returning: [])
                        return
                    }
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
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in
                            self?.recordQueryError(error, context: "Historisk sömndata")
                        }
                        continuation.resume(returning: [])
                        return
                    }
                    let asleepValues = [
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ]
                    let intervals = ((samples as? [HKCategorySample]) ?? [])
                        .filter { asleepValues.contains($0.value) }
                        .map { SleepInterval(start: $0.startDate, end: $0.endDate) }
                    let daily = SleepSessionCalculator.dailyPrimarySessions(intervals: intervals).map {
                        DailyBaselineSample(day: Calendar.current.startOfDay(for: $0.end), value: $0.duration / 3600)
                    }
                    continuation.resume(returning: daily)
                }
            store.execute(query)
        }
    }

    /// Returns the last 90 days of actual Apple Health body-mass samples.
    private func historicalWeightSamples() async -> [HealthTrendPoint] {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return [] }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -90, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Vikthistorik") }
                        continuation.resume(returning: [])
                        return
                    }
                    let values = ((samples as? [HKQuantitySample]) ?? []).map {
                        HealthTrendPoint(date: $0.endDate, value: $0.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                    }
                    continuation.resume(returning: values)
                }
            store.execute(query)
        }
    }

    /// Returns the last 30 days of actual HealthKit quantity samples for trend comparisons.
    private func historicalQuantitySamples(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        context: String
    ) async -> [HealthTrendPoint] {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ) { [weak self] _, samples, error in
                if let error {
                    Task { @MainActor [weak self] in self?.recordQueryError(error, context: context) }
                    continuation.resume(returning: [])
                    return
                }
                let values = ((samples as? [HKQuantitySample]) ?? []).compactMap { sample -> HealthTrendPoint? in
                    let value = sample.quantity.doubleValue(for: unit)
                    guard value.isFinite, value > 0 else { return nil }
                    return HealthTrendPoint(date: sample.endDate, value: value)
                }
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    /// Blood pressure is read from paired HealthKit correlations, never from unpaired values.
    private func historicalBloodPressureSamples() async -> [BloodPressureTrendPoint] {
        guard let correlationType = HKObjectType.correlationType(forIdentifier: .bloodPressure),
              let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return [] }
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -90, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: correlationType, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Blodtryckshistorik") }
                        continuation.resume(returning: [])
                        return
                    }
                    let unit = HKUnit.millimeterOfMercury()
                    let values = ((samples as? [HKCorrelation]) ?? []).compactMap { correlation -> BloodPressureTrendPoint? in
                        guard let systolic = correlation.objects(for: systolicType).first as? HKQuantitySample,
                              let diastolic = correlation.objects(for: diastolicType).first as? HKQuantitySample else { return nil }
                        return BloodPressureTrendPoint(
                            date: correlation.endDate,
                            systolic: systolic.quantity.doubleValue(for: unit),
                            diastolic: diastolic.quantity.doubleValue(for: unit)
                        )
                    }
                    continuation.resume(returning: values)
                }
            store.execute(query)
        }
    }

    private func latestBloodPressureSample() async -> (systolic: Double, diastolic: Double, date: Date)? {
        guard let correlationType = HKObjectType.correlationType(forIdentifier: .bloodPressure),
              let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: correlationType, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Blodtrycksdata") }
                        continuation.resume(returning: nil)
                        return
                    }
                    guard let correlation = samples?.first as? HKCorrelation,
                          let systolic = correlation.objects(for: systolicType).first as? HKQuantitySample,
                          let diastolic = correlation.objects(for: diastolicType).first as? HKQuantitySample else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let unit = HKUnit.millimeterOfMercury()
                    continuation.resume(returning: (
                        systolic.quantity.doubleValue(for: unit),
                        diastolic.quantity.doubleValue(for: unit),
                        correlation.endDate
                    ))
                }
            store.execute(query)
        }
    }

    private func latestQuantitySample(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> (value: Double, date: Date)? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Senaste hälsomätningen") }
                        continuation.resume(returning: nil)
                        return
                    }
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.endDate))
                }
            store.execute(query)
        }
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Senaste hälsomätningen") }
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
                }
            store.execute(query)
        }
    }

    private func todaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error {
                    Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Dagens aktivitetsdata") }
                    continuation.resume(returning: nil)
                    return
                }
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
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in self?.recordQueryError(error, context: "Puls- och aktivitetsdata") }
                        continuation.resume(returning: [])
                        return
                    }
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
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
                    if let error {
                        Task { @MainActor [weak self] in
                            self?.recordQueryError(error, context: "Sömndata")
                        }
                        continuation.resume(returning: nil)
                        return
                    }
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
