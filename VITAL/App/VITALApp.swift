import SwiftUI

@main
struct VITALApp: App {
    @StateObject private var healthStore = HealthKitStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(healthStore)
                .preferredColorScheme(.dark)
        }
    }
}