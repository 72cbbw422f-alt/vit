import Foundation
import Combine
import HealthKit

@MainActor
final class HealthKitStore: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationRequested = false
    @Published private(set) var lastError: String?
    private let store = HKHealthStore()

    func requestAccessAndRefresh() async {
        guard isAvailable else {
            lastError = "Apple Hälsa är inte tillgängligt på den här enheten."
            return
        }
        guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let resting = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
              let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            lastError = "Kunde inte läsa in alla hälsodatatyper."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleep, resting, hrv, steps, energy, weight])
            authorizationRequested = true
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refresh() async {
        async let sleepValue = latestSleepDuration()
        async let restingValue = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrvValue = latestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let stepsValue = todaySum(.stepCount, unit: .count())
        async let energyValue = todaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let weightValue = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        snapshot = await HealthSnapshot(sleepDuration: sleepValue, restingHeartRate: restingValue,
            hrv: hrvValue, steps: stepsValue, activeEnergy: energyValue,
            latestWeight: weightValue, lastUpdated: Date())
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

    private func latestSleepDuration() async -> TimeInterval? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                    let asleepValues = [
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ]
                    let asleep = (samples as? [HKCategorySample])?.filter { asleepValues.contains($0.value) } ?? []
                    let seconds = asleep.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    continuation.resume(returning: seconds > 0 ? seconds : nil)
                }
            store.execute(query)
        }
    }
}