import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var health: HealthKitStore
    @Environment(\.scenePhase) private var scenePhase
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
                    morningReportCard
                    eveningReportCard
                    reportHistoryCard
                    metricGrid
                    energyCard
                    activityCard
                    habitsCard
                }.padding(.horizontal, VITALSpacing.page).padding(.top, 12).padding(.bottom, 28)
            }
        }
        .task { if !health.authorizationRequested { await health.requestAccessAndRefresh() } }
        .refreshable { await health.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await health.refresh() }
            }
        }
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
    private var morningReportCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MORGONRAPPORT").font(.subheadline.weight(.semibold)).tracking(0.6)
                        .foregroundStyle(VITALPalette.muted)
                    Spacer()
                    if let report = health.morningReport {
                        Text(report.capturedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit()).foregroundStyle(VITALPalette.teal)
                    } else {
                        Text("Inväntar huvudsömn").font(.caption).foregroundStyle(VITALPalette.amber)
                    }
                }
                if let report = health.morningReport {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(report.recoveryScore.map(String.init) ?? "—")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(VITALPalette.cloud)
                        Text("/ 100 återhämtning").font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                    reportRow("Sömn", value: report.sleepDurationSeconds.map { duration in
                        let hours = Int(duration) / 3600
                        let minutes = (Int(duration) % 3600) / 60
                        return "\(hours) h \(String(format: "%02d", minutes)) min"
                    } ?? "—")
                    reportRow("HRV under sömn", value: report.hrvMilliseconds.map { "\(Int($0.rounded())) ms" } ?? "—")
                    reportRow("Vilopuls under sömn", value: report.restingHeartRateBPM.map { "\(Int($0.rounded())) bpm" } ?? "—")
                    reportRow("Steg vid rapporttillfället", value: report.steps.map { Int($0).formatted() } ?? "—")
                    Text("Fryst rapport · värdena ändras inte när ny hälsodata kommer in.")
                        .font(.caption2).foregroundStyle(VITALPalette.muted)
                } else {
                    Text("Rapporten skapas när VITAL har registrerat en avslutad huvudsömn. Den sparas sedan som en oföränderlig ögonblicksbild.")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var eveningReportCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("KVÄLLSRAPPORT").font(.subheadline.weight(.semibold)).tracking(0.6)
                        .foregroundStyle(VITALPalette.muted)
                    Spacer()
                    if let report = health.eveningReport {
                        Text(report.capturedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit()).foregroundStyle(VITALPalette.teal)
                    } else {
                        Text("Kl. 21:00").font(.caption).foregroundStyle(VITALPalette.amber)
                    }
                }
                if let report = health.eveningReport {
                    reportRow("Steg", value: report.steps.map { Int($0).formatted() } ?? "—")
                    reportRow("Aktiv energi", value: report.activeEnergyKcal.map { "\(Int($0.rounded())) kcal" } ?? "—")
                    reportRow("Puls", value: report.restingHeartRateBPM.map { "\(Int($0.rounded())) bpm" } ?? "—")
                    reportRow("Kroppsbatteri", value: report.bodyBatteryScore.map { "\($0) / 100" } ?? "—")
                    Text("Fryst rapport · fångad vid första uppdateringen efter kl. 21:00.")
                        .font(.caption2).foregroundStyle(VITALPalette.muted)
                } else {
                    Text("En påminnelse skickas kl. 21:00. Öppna VITAL så hämtas dagens data och kvällsrapporten sparas.")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var reportHistoryCard: some View {
        let history = Array(health.reportHistory.prefix(5))
        return Group {
            if !history.isEmpty {
                VITALCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TIDIGARE RAPPORTER")
                            .font(.subheadline.weight(.semibold)).tracking(0.6)
                            .foregroundStyle(VITALPalette.muted)
                        ForEach(history) { report in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(report.kind == .morning ? "Morgonrapport" : "Kvällsrapport")
                                        .font(.subheadline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                                    Text(report.localDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                                        .font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                                Spacer()
                                Text(report.recoveryScore.map { "\($0) / 100" } ?? "—")
                                    .font(.headline.monospacedDigit()).foregroundStyle(VITALPalette.teal)
                            }
                            if report.id != history.last?.id {
                                Divider().overlay(VITALPalette.track)
                            }
                        }
                    }
                }
            }
        }
    }

    private func reportRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text(value).foregroundStyle(VITALPalette.cloud).monospacedDigit()
        }.font(.caption)
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
        let battery = health.snapshot.bodyBattery
        return VITALCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Kroppsbatteri").font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                    Spacer()
                    Text(battery?.score.map { String($0) } ?? "—")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(VITALPalette.teal).monospacedDigit()
                    Text("/ 100").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.muted)
                }
                if let score = battery?.score {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(VITALPalette.track)
                            Capsule().fill(VITALPalette.teal)
                                .frame(width: proxy.size.width * CGFloat(score) / 100)
                        }
                    }.frame(height: 9)
                } else {
                    RoundedRectangle(cornerRadius: 5).fill(VITALPalette.track).frame(height: 9)
                }
                Text(battery?.explanation ?? "Kroppsbatteriet väntar på nattens återhämtning och tillräckligt med pulsdata.")
                    .font(.caption).foregroundStyle(VITALPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let battery, battery.score != nil {
                    HStack {
                        Label("\(battery.heartRateSampleCount) pulsmätningar", systemImage: "heart")
                        Spacer()
                        Text("\(Int(battery.activeEnergyKcal.rounded())) kcal aktiv energi")
                    }.font(.caption2).foregroundStyle(VITALPalette.teal)
                }
                Text("Preliminär uppskattning – inte ett medicinskt mått.")
                    .font(.caption2).foregroundStyle(VITALPalette.amber)
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
