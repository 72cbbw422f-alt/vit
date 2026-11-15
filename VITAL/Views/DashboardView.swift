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
        VITALCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("DAGENS STATUS").font(.subheadline.weight(.semibold)).tracking(0.6).foregroundStyle(VITALPalette.muted)
                    Spacer()
                    Text("Under uppbyggnad").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.amber)
                        .padding(.horizontal, 11).padding(.vertical, 6).background(VITALPalette.amber.opacity(0.13), in: Capsule())
                }
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("—").font(.system(size: 48, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                    Text("/ 100").font(.title2.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                }
                Text("Din personliga återhämtningsbedömning visas när beräkningsunderlaget är klart.")
                    .foregroundStyle(VITALPalette.muted).fixedSize(horizontal: false, vertical: true)
                ProgressView(value: 0).tint(VITALPalette.teal)
                HStack { Text("Nattlig återhämtning"); Spacer(); Text("Inväntar data") }
                    .font(.subheadline).foregroundStyle(VITALPalette.muted)
            }
        }
    }
    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(title: "SÖMN", value: health.snapshot.sleepText, detail: "Från Apple Hälsa", accent: VITALPalette.violet)
            MetricCard(title: "HRV", value: health.snapshot.hrvText, detail: "Senaste registrering", accent: VITALPalette.teal)
            MetricCard(title: "VILOPULS", value: health.snapshot.restingHeartRateText, detail: "Senaste registrering", accent: VITALPalette.teal)
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
                Text("Avvaktar tillräcklig historik").font(.title2.bold()).foregroundStyle(VITALPalette.teal)
                EnergyChartPlaceholder().frame(height: 132)
                Text("Historik och eventuell prognos visas separat.").font(.caption).foregroundStyle(VITALPalette.muted)
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
        VStack {
            GeometryReader { proxy in
                Path { path in
                    let points: [CGPoint] = [.init(x: 0, y: 0.78), .init(x: 0.18, y: 0.62),
                        .init(x: 0.34, y: 0.66), .init(x: 0.51, y: 0.32), .init(x: 0.68, y: 0.40),
                        .init(x: 0.84, y: 0.48), .init(x: 1, y: 0.27)]
                    for (index, point) in points.enumerated() {
                        let p = CGPoint(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                }.stroke(LinearGradient(colors: [VITALPalette.violet, VITALPalette.teal], startPoint: .leading, endPoint: .trailing),
                         style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            HStack {
                Text("00:00"); Spacer(); Text("06:00"); Spacer(); Text("12:00"); Spacer(); Text("18:00")
            }.font(.caption).foregroundStyle(VITALPalette.muted)
        }
    }
}