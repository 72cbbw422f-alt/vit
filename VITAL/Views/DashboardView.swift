import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var health: HealthKitStore
    private var dateTitle: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased()
    }
    var body: some View {
        ZStack {
            VITALPalette.surface.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    statusCard
                    metricGrid
                    energyCard
                    activityCard
                    habitsCard
                }.padding(.horizontal, VITALSpacing.page).padding(.top, 12).padding(.bottom, 28)
            }
        }
        .task { if !health.authorizationRequested { await health.requestAccessAndRefresh() } }
        .refreshable { await health.refresh() }
    }
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(dateTitle).font(.subheadline.weight(.semibold)).tracking(0.7).foregroundStyle(VITALPalette.muted)
                Text("Din hälsa").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
            }
            Spacer()
            Image(systemName: "calendar").font(.title3.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                .frame(width: 54, height: 54).background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18))
        }
    }
    private var statusCard: some View {
        let result = health.snapshot.recoveryResult
        return VITALCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("NATTENS ÅTERHÄMTNING").font(.subheadline.weight(.semibold)).tracking(0.6).foregroundStyle(VITALPalette.muted)
                    Spacer()
                    Text(result.score == nil ? "Under uppbyggnad" : "Prototyp")
                        .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.amber)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(VITALPalette.amber.opacity(0.13), in: Capsule())
                }
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(result.score.map { String($0) } ?? "—")
                        .font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                    Text("/ 100").font(.title2.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                }
                Text(result.explanation)
                    .foregroundStyle(VITALPalette.muted).fixedSize(horizontal: false, vertical: true)
                if let score = result.score {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(VITALPalette.track)
                            Capsule().fill(VITALPalette.teal).frame(width: proxy.size.width * CGFloat(score) / 100)
                        }
                    }.frame(height: 8)
                    componentRow("Sömn", value: result.sleepComponent)
                    componentRow("HRV", value: result.hrvComponent)
                    componentRow("Vilopuls", value: result.restingPulseComponent)
                } else {
                    RoundedRectangle(cornerRadius: 4).fill(VITALPalette.track).frame(height: 8)
                    HStack { Text("Personlig baslinje"); Spacer(); Text(baselineStatus) }
                        .font(.subheadline).foregroundStyle(VITALPalette.muted)
                }
                Text("Experimentell wellness-uppskattning – inte medicinskt validerad.")
                    .font(.caption2).foregroundStyle(VITALPalette.amber)
            }
        }
    }
    private var baselineStatus: String {
        let days = min(
            health.snapshot.sleepBaseline?.validDays ?? 0,
            health.snapshot.hrvBaseline?.validDays ?? 0,
            health.snapshot.restingHeartRateBaseline?.validDays ?? 0
        )
        return "\(days)/14 dagar"
    }
    private func componentRow(_ title: String, value: Double?) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text(value.map { "\(Int($0.rounded())) / 100" } ?? "—")
                .foregroundStyle(VITALPalette.cloud).monospacedDigit()
        }.font(.caption.weight(.medium))
    }
    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "SÖMN", value: health.snapshot.sleepText, detail: health.snapshot.sleepDuration == nil ? "Ingen sömndata" : "Apple Hälsa", accent: VITALPalette.violet)
            MetricCard(title: "HRV", value: health.snapshot.hrvText, detail: health.snapshot.hrv == nil ? "Ingen mätning" : "Senaste registrering", accent: VITALPalette.teal)
            MetricCard(title: "VILOPULS", value: health.snapshot.restingHeartRateText, detail: health.snapshot.restingHeartRate == nil ? "Ingen mätning" : "Senaste registrering", accent: VITALPalette.teal)
            MetricCard(title: "STRESS", value: "—", detail: "Ingen direkt mätning", accent: VITALPalette.amber)
        }
    }
    private var energyCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Kroppens energinivå").font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text("—").font(.subheadline.weight(.bold)).foregroundStyle(VITALPalette.muted)
                }
                Text("Avvaktar separat modell").font(.title2.bold()).foregroundStyle(VITALPalette.teal)
                EnergyChartPlaceholder().frame(height: 132)
                Text("Kroppsbatteriet utvecklas separat från nattens återhämtning.").font(.caption).foregroundStyle(VITALPalette.muted)
            }
        }
    }
    private var activityCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Dagens rörelse").font(.headline).foregroundStyle(VITALPalette.cloud)
                HStack(alignment: .firstTextBaseline) {
                    Text(health.snapshot.stepsText).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text("Steg").font(.subheadline).foregroundStyle(VITALPalette.muted)
                }
                ProgressView(value: min((health.snapshot.steps ?? 0) / 8000, 1)).tint(VITALPalette.teal)
                HStack {
                    Text("Mål: 8 000 steg"); Spacer()
                    Text(health.snapshot.steps == nil ? "Inväntar data" : "Från Apple Hälsa")
                }.font(.caption).foregroundStyle(VITALPalette.muted)
                Divider().overlay(VITALPalette.track)
                HStack {
                    Label("Träning", systemImage: "figure.run").foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text("Aktivitetssammanställning kommer").font(.caption).foregroundStyle(VITALPalette.muted)
                }
            }
        }
    }
    private var habitsCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Dagens vanor").font(.headline).foregroundStyle(VITALPalette.cloud)
                HStack {
                    Label("Datainsamling", systemImage: "heart.text.square").foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text(health.isAvailable ? "Apple Hälsa" : "Ej tillgängligt").font(.subheadline).foregroundStyle(VITALPalette.teal)
                }
                if let error = health.lastError { Text(error).font(.caption).foregroundStyle(VITALPalette.amber) }
            }
        }
    }
}
private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.medium)).foregroundStyle(VITALPalette.muted)
            Text(value).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud).lineLimit(1).minimumScaleFactor(0.75)
            Text(detail).font(.caption).foregroundStyle(accent).lineLimit(2)
        }.frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(16)
            .background(VITALPalette.midnight, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct EnergyChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(VITALPalette.surface)
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(VITALPalette.track.opacity(0.65)).frame(height: 1)
                        Spacer(minLength: 0)
                    }
                }.padding(.vertical, 16).padding(.horizontal, 8)
                Text("Diagram visas när historiska mätvärden finns")
                    .font(.caption).foregroundStyle(VITALPalette.muted)
                    .multilineTextAlignment(.center).padding(.horizontal, 18)
            }
            .frame(height: 100)
            HStack {
                Text("00:00"); Spacer(); Text("06:00"); Spacer(); Text("12:00"); Spacer(); Text("18:00")
            }.font(.caption).foregroundStyle(VITALPalette.muted)
        }
    }
}
