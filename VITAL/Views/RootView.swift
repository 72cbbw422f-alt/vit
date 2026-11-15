import SwiftUI
import Charts

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Idag", systemImage: "house.fill") }
            InsightsView().tabItem { Label("Insikter", systemImage: "chart.xyaxis.line") }
            ActivityView().tabItem { Label("Aktivitet", systemImage: "figure.walk") }
            HealthOverviewView().tabItem { Label("Hälsa", systemImage: "heart.text.square") }
        }
        .tint(VITALPalette.teal)
    }
}

private struct InsightsView: View {
    @EnvironmentObject private var health: HealthKitStore
    private var recoveryReports: [DailyReportSnapshot] {
        health.reportHistory.filter { $0.kind == .morning && $0.recoveryScore != nil }.suffix(14).map { $0 }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        pageHeader("Insikter", subtitle: "Dina mönster över tid")
                        VITALCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Återhämtning", systemImage: "waveform.path.ecg")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                if recoveryReports.isEmpty {
                                    EmptyChartState(symbol: "chart.xyaxis.line", title: "Ingen trend ännu", detail: "Morgonrapporter med giltiga återhämtningsvärden visas här när de finns.")
                                } else {
                                    Chart(Array(recoveryReports.enumerated()), id: \.element.id) { index, report in
                                        BarMark(
                                            x: .value("Dag", index),
                                            y: .value("Återhämtning", report.recoveryScore ?? 0)
                                        )
                                        .foregroundStyle(VITALPalette.teal.gradient)
                                        .cornerRadius(5)
                                    }
                                    .chartYScale(domain: 0...100)
                                    .chartXAxis(.hidden)
                                    .chartYAxis {
                                        AxisMarks(position: .leading, values: [0, 50, 100]) { value in
                                            AxisGridLine().foregroundStyle(VITALPalette.track)
                                            AxisValueLabel().foregroundStyle(VITALPalette.muted)
                                        }
                                    }
                                    .frame(height: 180)
                                    Text("\(recoveryReports.count) sparade morgonvärden")
                                        .font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            InsightMetric(title: "Sömn", value: health.snapshot.sleepText, symbol: "moon.stars.fill", tint: VITALPalette.violet)
                            InsightMetric(title: "HRV", value: health.snapshot.hrvText, symbol: "waveform.path", tint: VITALPalette.teal)
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Personlig baslinje", systemImage: "person.crop.circle")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                baselineRow("Sömn", days: health.snapshot.sleepBaseline?.validDays ?? 0)
                                baselineRow("HRV", days: health.snapshot.hrvBaseline?.validDays ?? 0)
                                baselineRow("Vilopuls", days: health.snapshot.restingHeartRateBaseline?.validDays ?? 0)
                            }
                        }
                        Text("Trender visas endast när sparade mätvärden finns. VITAL fyller aldrig ut luckor med uppskattade datapunkter.")
                            .font(.caption).foregroundStyle(VITALPalette.muted).padding(.horizontal, 4)
                    }.padding(.horizontal, VITALSpacing.page).padding(.top, 14).padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    private func baselineRow(_ title: String, days: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text("\(days)/14 dagar").font(.subheadline.monospacedDigit()).foregroundStyle(days >= 14 ? VITALPalette.teal : VITALPalette.amber)
        }.padding(.vertical, 5)
    }
}

private struct ActivityView: View {
    @EnvironmentObject private var health: HealthKitStore
    private var steps: Double? { health.snapshot.steps }
    private var progress: Double { min(max((steps ?? 0) / 8000, 0), 1) }
    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        pageHeader("Aktivitet", subtitle: "Rörelse och belastning idag")
                        VITALCard {
                            HStack(spacing: 22) {
                                ActivityProgressRing(progress: progress, hasData: steps != nil)
                                    .frame(width: 142, height: 142)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(health.snapshot.stepsText).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud).minimumScaleFactor(0.7).lineLimit(1)
                                    Text("steg idag").font(.subheadline).foregroundStyle(VITALPalette.muted)
                                    Text("Mål 8 000").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        HStack(spacing: 12) {
                            InsightMetric(title: "Aktiv energi", value: health.snapshot.activeEnergy.map { "\(Int($0.rounded())) kcal" } ?? "—", symbol: "flame.fill", tint: VITALPalette.amber)
                            InsightMetric(title: "Kroppsbatteri", value: health.snapshot.bodyBattery?.score.map { "\($0)/100" } ?? "—", symbol: "battery.100percent", tint: VITALPalette.violet)
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Dagens aktivitet", systemImage: "figure.run").font(.headline).foregroundStyle(VITALPalette.cloud)
                                activityStatusRow("Steg", steps == nil ? "Saknas" : "Registrerat")
                                activityStatusRow("Aktiv energi", health.snapshot.activeEnergy == nil ? "Saknas" : "Registrerat")
                                activityStatusRow("Pulsmätningar", health.snapshot.bodyBattery.map { "\($0.heartRateSampleCount) st" } ?? "Saknas")
                            }
                        }
                        Text("Aktivitetsdata hämtas från Apple Hälsa. Kroppsbatteriet är en preliminär uppskattning, inte ett medicinskt mått.")
                            .font(.caption).foregroundStyle(VITALPalette.muted).padding(.horizontal, 4)
                    }.padding(.horizontal, VITALSpacing.page).padding(.top, 14).padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    private func activityStatusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(value == "Saknas" ? VITALPalette.amber : VITALPalette.teal)
        }
    }
}

private struct HealthOverviewView: View {
    @EnvironmentObject private var health: HealthKitStore
    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        pageHeader("Hälsa", subtitle: "Dina viktigaste hälsomått")
                        VITALCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Hjärt & kärl", systemImage: "heart.fill")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                HStack(spacing: 12) {
                                    HealthValueTile(title: "Vilopuls", value: health.snapshot.restingHeartRateText, tint: VITALPalette.teal)
                                    HealthValueTile(title: "HRV", value: health.snapshot.hrvText, tint: VITALPalette.violet)
                                }
                            }
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Kropp & vikt", systemImage: "scalemass.fill")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(health.snapshot.latestWeight.map { String(format: "%.1f", $0) } ?? "—")
                                        .font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                                    Text(health.snapshot.latestWeight == nil ? "Inväntar viktdata" : "kg · Apple Hälsa")
                                        .font(.subheadline).foregroundStyle(VITALPalette.muted)
                                }
                            }
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Sömn", systemImage: "moon.stars.fill").font(.headline).foregroundStyle(VITALPalette.cloud)
                                HStack(alignment: .firstTextBaseline) {
                                    Text(health.snapshot.sleepText).font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.violet)
                                    Spacer()
                                    Text("senaste huvudsömn").font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                            }
                        }
                        if let updated = health.snapshot.lastUpdated {
                            Text("Senast uppdaterad \(updated.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(VITALPalette.muted).padding(.horizontal, 4)
                        }
                    }.padding(.horizontal, VITALSpacing.page).padding(.top, 14).padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct InsightMetric: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color
    var body: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).font(.title3).foregroundStyle(tint)
                Text(title).font(.caption.weight(.medium)).foregroundStyle(VITALPalette.muted)
                Text(value).font(.title2.bold().rounded()).foregroundStyle(VITALPalette.cloud).minimumScaleFactor(0.7).lineLimit(1)
            }
        }
    }
}
private struct HealthValueTile: View {
    let title: String
    let value: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(VITALPalette.muted)
            Text(value).font(.title2.bold().rounded()).foregroundStyle(tint).minimumScaleFactor(0.7).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct EmptyChartState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: symbol).font(.system(size: 28)).foregroundStyle(VITALPalette.teal)
            Text(title).font(.headline).foregroundStyle(VITALPalette.cloud)
            Text(detail).font(.caption).foregroundStyle(VITALPalette.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 22)
    }
}
private struct ActivityProgressRing: View {
    let progress: Double
    let hasData: Bool
    var body: some View {
        ZStack {
            Circle().stroke(VITALPalette.track, lineWidth: 12)
            Circle().trim(from: 0, to: hasData ? progress : 0)
                .stroke(VITALPalette.teal.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 3) {
                Image(systemName: "figure.walk").font(.title2).foregroundStyle(VITALPalette.teal)
                Text(hasData ? "\(Int(progress * 100))%" : "—").font(.headline.monospacedDigit()).foregroundStyle(VITALPalette.cloud)
            }
        }
    }
}
private func pageHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
            .font(.caption.weight(.semibold)).tracking(0.7).foregroundStyle(VITALPalette.muted)
        Text(title).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
        Text(subtitle).font(.subheadline).foregroundStyle(VITALPalette.muted)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
}
