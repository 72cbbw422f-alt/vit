import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Idag", systemImage: "house.fill") }
            PlaceholderView(title: "Insikter", subtitle: "Dina trender och personliga analyser.", symbol: "chart.xyaxis.line")
                .tabItem { Label("Insikter", systemImage: "chart.xyaxis.line") }
            PlaceholderView(title: "Aktivitet", subtitle: "Rörelse, träning och aktivitetsmönster.", symbol: "figure.walk")
                .tabItem { Label("Aktivitet", systemImage: "figure.walk") }
            PlaceholderView(title: "Hälsa", subtitle: "Dina mätvärden och hälsodata.", symbol: "heart.text.square")
                .tabItem { Label("Hälsa", systemImage: "heart.text.square") }
        }.tint(VITALPalette.teal)
    }
}
struct PlaceholderView: View {
    let title: String
    let subtitle: String
    let symbol: String
    var body: some View {
        ZStack {
            VITALPalette.surface.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: symbol).font(.system(size: 34, weight: .medium)).foregroundStyle(VITALPalette.teal)
                Text(title).font(.largeTitle.bold()).foregroundStyle(VITALPalette.cloud)
                Text(subtitle).foregroundStyle(VITALPalette.muted).multilineTextAlignment(.center)
            }.padding(30)
        }
    }
}