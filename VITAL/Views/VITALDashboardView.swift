import SwiftUI

/// VITAL 3.0 — redesigned Midnight dashboard.
struct VITALDashboardView: View {
    @EnvironmentObject private var health: HealthKitStore
    @Environment(\.scenePhase) private var scenePhase

    private var recovery: RecoveryResult { health.snapshot.recoveryResult }
    private var guidance: RecoveryGuidance {
        RecoveryGuidancePolicy.evaluate(sleep: recovery.sleepComponent, hrv: recovery.hrvComponent, restingPulse: recovery.restingPulseComponent)
    }
    private var recoveryTint: Color { guidance.hasAttentionSignal ? VITALPalette.amber : VITALPalette.lime }

    var body: some View {
        ZStack {
            VITALPalette.ink.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    recoveryHero
                    quickMetrics
                    bodyBatteryPanel
                    movementPanel
                    baselinePanel
                    dataFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
        }
        .task { if !health.authorizationRequested { await health.requestAccessAndRefresh() } }
        .refreshable { await health.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await health.refresh() } }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.8)
                    .foregroundStyle(VITALPalette.steel)
                Text("Överblick")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(VITALPalette.paper)
            }
            Spacer()
            ZStack {
                Circle().fill(VITALPalette.lime.opacity(0.10)).frame(width: 44, height: 44)
                Image(systemName: "waveform.path.ecg").font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(VITALPalette.lime)
            }
            .overlay(Circle().stroke(VITALPalette.lime.opacity(0.24), lineWidth: 1))
        }
    }

    private var recoveryHero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x182B3A), Color(hex: 0x111D2A), Color(hex: 0x17233A)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().stroke(VITALPalette.lime.opacity(0.08), lineWidth: 1).frame(width: 230).offset(x: 90, y: -105)
            Circle().stroke(VITALPalette.lime.opacity(0.06), lineWidth: 1).frame(width: 290).offset(x: 110, y: -130)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("NATTENS ÅTERHÄMTNING", systemImage: "moon.stars.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.3)
                        .foregroundStyle(VITALPalette.steel)
                    Spacer()
                    Text("PERSONLIG BASLINJE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(1)
                        .foregroundStyle(VITALPalette.lime)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(VITALPalette.lime.opacity(0.10), in: Capsule())
                }
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 12)
                        Circle().trim(from: 0, to: CGFloat(max(0, min(recovery.score ?? 0, 100))) / 100)
                            .stroke(AngularGradient(colors: [VITALPalette.lime, Color(hex: 0xB8F36A), Color(hex: 0x4CAFA0)], center: .center), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Circle().stroke(VITALPalette.lime.opacity(0.13), lineWidth: 1).padding(17)
                        VStack(spacing: 1) {
                            Text(recovery.score.map(String.init) ?? "—")
                                .font(.system(size: 39, weight: .bold, design: .rounded)).monospacedDigit()
                                .foregroundStyle(VITALPalette.paper)
                            Text("/ 100").font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(VITALPalette.steel)
                        }
                    }
                    .frame(width: 132, height: 132)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(guidance.title.uppercased())
                            .font(.system(size: 14, weight: .heavy, design: .rounded)).tracking(0.8)
                            .foregroundStyle(recoveryTint)
                        Text(recovery.score == nil ? recovery.explanation : guidance.detail)
                            .font(.system(size: 12, weight: .medium)).lineSpacing(3)
                            .foregroundStyle(Color(hex: 0xB9C6D2))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                HStack(spacing: 0) {
                    heroFact("SÖMN", value: health.snapshot.sleepText, icon: "bed.double.fill")
                    Spacer(minLength: 8)
                    heroFact("HRV", value: health.snapshot.overnightHRV.map { "\(Int($0.rounded())) ms" } ?? "—", icon: "waveform.path")
                    Spacer(minLength: 8)
                    heroFact("VILOPULS", value: health.snapshot.overnightRestingHeartRate.map { "\(Int($0.rounded()))" } ?? "—", icon: "heart.fill")
                }
                if !guidance.attentionSignals.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(guidance.attentionSignals, id: \.self) { signal in
                            Label(signal, systemImage: "exclamationmark.circle.fill")
                                .font(.system(size: 11, weight: .medium)).foregroundStyle(VITALPalette.amber)
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(VITALPalette.amber.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                }
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles").foregroundStyle(VITALPalette.lime)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DAGENS RIKTNING").font(.system(size: 9, weight: .heavy)).tracking(1.2).foregroundStyle(VITALPalette.lime)
                        Text(guidance.recommendation).font(.system(size: 12, weight: .medium)).foregroundStyle(VITALPalette.paper).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
        }
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: .black.opacity(0.22), radius: 22, y: 12)
    }

    private func heroFact(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.system(size: 8, weight: .bold)).tracking(0.8).foregroundStyle(VITALPalette.steel)
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(VITALPalette.paper)
        }
    }

    private var quickMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("NATTENS SIGNALER", subtitle: "Mätvärden från Apple Hälsa")
            HStack(spacing: 10) {
                signalTile("Sömn", value: health.snapshot.sleepText, detail: "Senaste huvudsömn", symbol: "bed.double.fill", tint: VITALPalette.lavender)
                signalTile("HRV", value: health.snapshot.overnightHRV.map { "\(Int($0.rounded())) ms" } ?? "—", detail: "Under sömn", symbol: "waveform.path.ecg", tint: VITALPalette.lime)
                signalTile("Puls", value: health.snapshot.overnightRestingHeartRate.map { "\(Int($0.rounded()))" } ?? "—", detail: "Vilopuls", symbol: "heart.fill", tint: VITALPalette.coral)
            }
        }
    }

    private func signalTile(_ title: String, value: String, detail: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol).font(.system(size: 14, weight: .semibold)).foregroundStyle(tint)
                .frame(width: 30, height: 30).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Text(title.uppercased()).font(.system(size: 8, weight: .heavy)).tracking(1).foregroundStyle(VITALPalette.steel)
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(VITALPalette.paper)
            Text(detail).font(.system(size: 8, weight: .medium)).foregroundStyle(VITALPalette.steel).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(11)
        .background(VITALPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.055), lineWidth: 1))
    }

    private var bodyBatteryPanel: some View {
        let battery = health.snapshot.bodyBattery
        return VStack(alignment: .leading, spacing: 13) {
            sectionHeading("KROPPSBATTERI", subtitle: "Dynamisk uppskattning under dagen")
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(VITALPalette.track, lineWidth: 10)
                    Circle().trim(from: 0, to: CGFloat(max(0, min(battery?.score ?? 0, 100))) / 100)
                        .stroke(AngularGradient(colors: [VITALPalette.lavender, Color(hex: 0x5D72C8), VITALPalette.lavender], center: .center), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "battery.100percent").font(.system(size: 22, weight: .medium)).foregroundStyle(VITALPalette.lavender)
                }.frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 5) {
                    Text(battery?.score.map(String.init) ?? "—").font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(VITALPalette.paper)
                    Text(battery?.explanation ?? "Inväntar tillräckliga mätningar").font(.system(size: 11)).foregroundStyle(VITALPalette.steel).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            HStack {
                miniStat("PULSMÄTNINGAR", value: battery.map { "\($0.heartRateSampleCount)" } ?? "—")
                Spacer()
                miniStat("AKTIV ENERGI", value: health.snapshot.activeEnergy.map { "\(Int($0.rounded())) kcal" } ?? "—")
                Spacer()
                miniStat("ÅTERHÄMTNING I VILA", value: battery.map { "+\(Int($0.recoveryGain.rounded()))" } ?? "—")
            }
            Text("Preliminär modell – inte ett medicinskt mått.")
                .font(.system(size: 9, weight: .medium)).foregroundStyle(VITALPalette.steel)
        }
        .padding(17).background(VITALPalette.panel, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color.white.opacity(0.055), lineWidth: 1))
    }

    private var movementPanel: some View {
        let steps = health.snapshot.steps
        let progress = min(max((steps ?? 0) / 8000, 0), 1)
        return VStack(alignment: .leading, spacing: 13) {
            sectionHeading("RÖRELSE IDAG", subtitle: "Ditt dagliga stegmål")
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(VITALPalette.track, lineWidth: 11)
                    Circle().trim(from: 0, to: steps == nil ? 0 : progress)
                        .stroke(VITALPalette.lime.gradient, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text(steps.map { "\(Int(min($0, 999999).rounded()))" } ?? "—")
                            .font(.system(size: 20, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1).foregroundStyle(VITALPalette.paper)
                        Text("STEG").font(.system(size: 8, weight: .heavy)).tracking(1).foregroundStyle(VITALPalette.steel)
                    }
                }.frame(width: 88, height: 88)
                VStack(alignment: .leading, spacing: 5) {
                    Text(steps == nil ? "Inväntar data" : "\(Int(progress * 100)) % av målet")
                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.paper)
                    Text("8 000 steg per dag").font(.system(size: 11)).foregroundStyle(VITALPalette.steel)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(VITALPalette.track)
                            Capsule().fill(VITALPalette.lime.gradient).frame(width: proxy.size.width * progress)
                        }
                    }.frame(height: 6)
                }
            }
            .padding(16).background(VITALPalette.panel, in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var baselinePanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading("DIN PERSONLIGA NORMALNIVÅ", subtitle: "Baslinjer byggs av dina egna mätningar")
            baselineRow("Sömn", value: health.snapshot.sleepBaseline?.median, suffix: "h", days: health.snapshot.sleepBaseline?.validDays ?? 0)
            baselineRow("HRV", value: health.snapshot.hrvBaseline?.median, suffix: "ms", days: health.snapshot.hrvBaseline?.validDays ?? 0)
            baselineRow("Vilopuls", value: health.snapshot.restingHeartRateBaseline?.median, suffix: "bpm", days: health.snapshot.restingHeartRateBaseline?.validDays ?? 0)
        }
        .padding(17).background(VITALPalette.panel, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.055), lineWidth: 1))
    }

    private func baselineRow(_ title: String, value: Double?, suffix: String, days: Int) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(VITALPalette.paper)
                Spacer()
                Text(value.map { "\(String(format: "%.1f", $0)) \(suffix)" } ?? "Samlar data")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(value == nil ? VITALPalette.amber : VITALPalette.lime)
                Text("\(days)/14").font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(VITALPalette.steel)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(VITALPalette.track)
                    Capsule().fill(VITALPalette.lime.opacity(0.75)).frame(width: proxy.size.width * min(Double(days) / 14, 1))
                }
            }.frame(height: 4)
        }
    }

    private var dataFooter: some View {
        HStack(spacing: 7) {
            Circle().fill(health.isAvailable ? VITALPalette.lime : VITALPalette.amber).frame(width: 6, height: 6)
            Text(health.isAvailable ? "SYNKRONISERAD MED APPLE HÄLSA" : "APPLE HÄLSA ÄR INTE TILLGÄNGLIG")
            Spacer()
            if let updated = health.snapshot.lastUpdated {
                Text(updated.formatted(date: .omitted, time: .shortened))
            }
        }
        .font(.system(size: 8, weight: .bold, design: .rounded)).tracking(0.6).foregroundStyle(VITALPalette.steel)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1.4).foregroundStyle(VITALPalette.lime)
            Text(subtitle).font(.system(size: 11, weight: .medium)).foregroundStyle(VITALPalette.steel)
        }
    }

    private func miniStat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 7, weight: .heavy)).tracking(0.5).foregroundStyle(VITALPalette.steel)
            Text(value).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.paper).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

private extension VITALPalette {
    static let ink = Color(hex: 0x0A111B)
    static let panel = Color(hex: 0x121E2B)
    static let paper = Color(hex: 0xF3F6F2)
    static let steel = Color(hex: 0x8798A9)
    static let lime = Color(hex: 0xC4F36B)
    static let lavender = Color(hex: 0x9A91F5)
    static let coral = Color(hex: 0xF18A7C)
}
