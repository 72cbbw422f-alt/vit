import SwiftUI
import BackgroundTasks
import UIKit

@MainActor
final class VitalAppDelegate: NSObject, UIApplicationDelegate {
    private weak var store: VitalStore?
    private weak var health: HealthStore?
    private let morningID = "app.walnut8211.radish6181.morning-refresh"
    private let eveningID = "app.walnut8211.radish6181.evening-refresh"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        registerBackgroundTasks()
        scheduleBackgroundRefreshes()
        return true
    }

    func configure(store: VitalStore, health: HealthStore) {
        self.store = store
        self.health = health
        scheduleBackgroundRefreshes()
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: morningID, using: nil) { [weak self] task in
            self?.handle(task as! BGAppRefreshTask, kind: .morning)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: eveningID, using: nil) { [weak self] task in
            self?.handle(task as! BGAppRefreshTask, kind: .evening)
        }
    }

    private func scheduleBackgroundRefreshes() {
        schedule(id: morningID, hour: 7, minute: 15)
        schedule(id: eveningID, hour: 20, minute: 15)
    }

    private func schedule(id: String, hour: Int, minute: Int) {
        let request = BGAppRefreshTaskRequest(identifier: id)
        var next = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        next.hour = hour
        next.minute = minute
        if let date = Calendar.current.date(from: next), date <= Date() {
            request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 1, to: date)
        } else {
            request.earliestBeginDate = Calendar.current.date(from: next)
        }
        do { try BGTaskScheduler.shared.submit(request) } catch {
            print("VITAL background refresh scheduling failed: \(error.localizedDescription)")
        }
    }

    private func handle(_ task: BGAppRefreshTask, kind: VitalReportKind) {
        let id = kind == .morning ? morningID : eveningID
        let hour = kind == .morning ? 7 : 20
        let minute = kind == .morning ? 15 : 15
        schedule(id: id, hour: hour, minute: minute)

        guard let health, let store else {
            task.setTaskCompleted(success: false)
            return
        }

        let work = Task { @MainActor in
            health.refresh()
            // HealthKit queries are asynchronous. Allow the refresh callbacks time to populate
            // the published values; the capture timestamp records the actual capture time.
            try? await Task.sleep(nanoseconds: 18_000_000_000)
            guard !Task.isCancelled else {
                task.setTaskCompleted(success: false)
                return
            }
            _ = store.captureReportIfNeeded(kind, health: health, source: "Förberedd i bakgrunden")
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}

@main
struct VITALApp: App {
    @UIApplicationDelegateAdaptor(VitalAppDelegate.self) private var appDelegate
    @StateObject private var store = VitalStore()
    @StateObject private var health = HealthStore()
    @StateObject private var notifications = VitalNotifications()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(health)
                .environmentObject(notifications)
                .preferredColorScheme(.dark)
                .onAppear { appDelegate.configure(store: store, health: health) }
        }
    }
}
