import SwiftUI

/// VITAL 3.0 — redesigned Midnight dashboard.
struct VITALDashboardView: View {
    @EnvironmentObject private var health: HealthKitStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("vital.mood.value") private var savedMood = ""
    @AppStorage("vital.mood.date") private var savedMoodDate = ""
    @State private var selectedMood = ""

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
                    bodyBatteryHero
                    recoverySummary
                    coachCard
                    moodCheckIn
                    quickMetrics
                    movementPanel
                    baselinePanel
                    dataFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
        }
        .task {
            restoreTodayMood()
            if !health.authorizationRequested { await health.requestAccessAndRefresh() }
        }
        .refreshable { await health.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await health.refresh() } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: VITALPalette.lime.opacity(0.12), radius: 10, y: 4)
                Rectangle().fill(Color.white.opacity(0.22)).frame(width: 1, height: 39)
                VStack(alignment: .leading, spacing: 3) {
                    Text("V I T A L")
                        .font(.vital(size: 26, weight: .medium, design: .rounded))
                        .foregroundStyle(VITALPalette.paper)
                    Text("HÄLSA  •  ÅTERHÄMTNING  •  BALANS")
                        .font(.vital(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(VITALPalette.steel)
                }
                Spacer()
                Image(systemName: "bell")
                    .font(.vital(size: 21.1, weight: .medium))
                    .foregroundStyle(VITALPalette.paper.opacity(0.9))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.045), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .accessibilityLabel("Notiser")
            }
            HStack(alignment: .lastTextBaseline) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized)
                    .font(.vital(size: 14.9, weight: .semibold, design: .rounded))
                    .foregroundStyle(VITALPalette.steel)
                Spacer()
                Text("ÖVERSIKT")
                    .font(.vital(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(VITALPalette.lime)
            }
        }
    }

    /// Main visual anchor: the live daytime body-battery estimate.
    private var bodyBatteryHero: some View {
        let battery = health.snapshot.bodyBattery
        let score = battery?.score
        let progress = CGFloat(max(0, min(score ?? 0, 100))) / 100
        return ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x172B3C), Color(hex: 0x0D1928), Color(hex: 0x101D2D)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(VITALPalette.lime.opacity(0.08)).frame(width: 210, height: 210).blur(radius: 55).offset(y: -18)
            VStack(spacing: 0) {
                Spacer()
                VITALWaveShape(phase: 0.0).fill(VITALPalette.lime.opacity(0.075)).frame(height: 92)
                VITALWaveShape(phase: 0.42).fill(Color(hex: 0x567C9A).opacity(0.12)).frame(height: 72).offset(y: -26)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .allowsHitTesting(false)
            VStack(spacing: 15) {
                HStack {
                    Label("KROPPSBATTERI", systemImage: "battery.100percent")
                        .font(.vital(size: 12, weight: .heavy, design: .rounded)).tracking(1.5)
                        .foregroundStyle(VITALPalette.steel)
                    Spacer()
                    Text("IDAG")
                        .font(.vital(size: 12, weight: .heavy)).tracking(1.1)
                        .foregroundStyle(VITALPalette.lime)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(VITALPalette.lime.opacity(0.10), in: Capsule())
                }
                ZStack {
                    Circle().stroke(Color.white.opacity(0.07), lineWidth: 15)
                    Circle().trim(from: 0, to: progress)
                        .stroke(AngularGradient(colors: [Color(hex: 0x8FBF45), VITALPalette.lime, Color(hex: 0xE4FF9B)], center: .center), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: VITALPalette.lime.opacity(0.45), radius: 12)
                    Circle().stroke(VITALPalette.lime.opacity(0.12), lineWidth: 1).padding(23)
                    VStack(spacing: 1) {
                        Image(systemName: "battery.100percent").font(.vital(size: 23.5, weight: .medium)).foregroundStyle(VITALPalette.lime)
                        Text(score.map(String.init) ?? "—")
                            .font(.vital(size: 67.1, weight: .bold, design: .rounded)).monospacedDigit()
                            .foregroundStyle(VITALPalette.paper)
                        Text("AV 100").font(.vital(size: 12, weight: .heavy)).tracking(1.5).foregroundStyle(VITALPalette.steel)
                    }
                }
                .frame(width: 190, height: 190)
                Text(score == nil ? "Samlar in data" : (score ?? 0) >= 75 ? "Bra energinivå" : (score ?? 0) >= 45 ? "Måttlig energinivå" : "Låg energinivå")
                    .font(.vital(size: 21.1, weight: .bold, design: .rounded))
                    .foregroundStyle(score == nil ? VITALPalette.steel : VITALPalette.lime)
                Text(battery?.explanation ?? "VITAL behöver fler pulsmätningar för att beräkna kroppsbatteriet.")
                    .font(.vital(size: 13.6, weight: .medium)).lineSpacing(3)
                    .multilineTextAlignment(.center).foregroundStyle(Color(hex: 0xB9C6D2))
                    .frame(maxWidth: 270)
                Rectangle().fill(Color.white.opacity(0.09)).frame(height: 1)
                HStack {
                    heroFact("PULSMÄTNINGAR", value: battery.map { "\($0.heartRateSampleCount)" } ?? "—", icon: "heart.fill")
                    Spacer()
                    heroFact("AKTIV ENERGI", value: health.snapshot.activeEnergy.map { "\(Int($0.rounded())) kcal" } ?? "—", icon: "flame.fill")
                    Spacer()
                    heroFact("ÅTERHÄMTNING I VILA", value: battery.map { "+\(Int($0.recoveryGain.rounded()))" } ?? "—", icon: "leaf.fill")
                }
                Text("Preliminär modell – inte ett medicinskt mått.")
                    .font(.vital(size: 12, weight: .medium)).foregroundStyle(VITALPalette.steel)
            }
            .padding(20)
        }
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: VITALPalette.lime.opacity(0.08), radius: 24, y: 12)
    }

    /// Overnight recovery stays distinct from the changing daytime body battery.
    private var recoverySummary: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(recoveryTint.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: "moon.stars.fill").font(.vital(size: 23.5, weight: .semibold)).foregroundStyle(recoveryTint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("NATTENS ÅTERHÄMTNING")
                    .font(.vital(size: 12, weight: .heavy)).tracking(1.1).foregroundStyle(VITALPalette.steel)
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(recovery.score.map(String.init) ?? "—")
                        .font(.vital(size: 31, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(VITALPalette.paper)
                    Text(guidance.title).font(.vital(size: 13.6, weight: .semibold)).foregroundStyle(recoveryTint)
                }
                Text("Baserad på sömn, HRV och vilopuls")
                    .font(.vital(size: 12, weight: .medium)).foregroundStyle(VITALPalette.steel)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.vital(size: 13.6, weight: .bold)).foregroundStyle(VITALPalette.steel)
        }
        .padding(15)
        .background(VITALPalette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    /// Daily coach copy is derived only from available overnight recovery signals and the user's own mood check-in.
    private var coachCard: some View {
        let insight = coachInsight
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("VITAL COACH", systemImage: "sparkles")
                    .font(.vital(size: 12, weight: .heavy)).tracking(1.2)
                    .foregroundStyle(VITALPalette.lime)
                Spacer()
                Text("DAGENS REFLEKTION")
                    .font(.vital(size: 12, weight: .heavy)).tracking(0.8)
                    .foregroundStyle(VITALPalette.steel)
            }
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: insight.symbol)
                    .font(.vital(size: 21.1, weight: .semibold))
                    .foregroundStyle(insight.tint)
                    .frame(width: 40, height: 40)
                    .background(insight.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 7) {
                    Text(insight.headline)
                        .font(.vital(size: 21.1, weight: .bold, design: .rounded))
                        .foregroundStyle(VITALPalette.paper)
                    Text(insight.detail)
                        .font(.vital(size: 13.6, weight: .medium))
                        .lineSpacing(3)
                        .foregroundStyle(Color(hex: 0xB9C6D2))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(insight.recommendation)
                        .font(.vital(size: 13.6, weight: .semibold))
                        .lineSpacing(2)
                        .foregroundStyle(insight.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Divider().overlay(Color.white.opacity(0.08))
            Text("Bygger på tillgängliga nattvärden och din egen måenderegistrering. Väg alltid in hur kroppen känns.")
                .font(.vital(size: 12, weight: .medium))
                .foregroundStyle(VITALPalette.steel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(hex: 0x192B3A), VITALPalette.panel], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(VITALPalette.lime.opacity(0.16), lineWidth: 1))
    }

    private var coachInsight: (headline: String, detail: String, recommendation: String, symbol: String, tint: Color) {
        let score = recovery.score
        let variation = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let goodOpeners = [
            "Dina nattliga signaler ser lovande ut.",
            "Det finns flera positiva tecken i nattens återhämtning.",
            "Dagens utgångsläge ser starkt ut."
        ]
        let carefulOpeners = [
            "Kroppen kan behöva lite extra utrymme idag.",
            "Nattens signaler talar för en mjukare start.",
            "Det kan vara klokt att sänka tempot något."
        ]
        if selectedMood == "low" || selectedMood == "okay" {
            let headline = selectedMood == "low" ? "Ge dagsformen första ordet." : "Lyssna in kroppen idag."
            let detail = score.map { $0 >= 75
                ? "Mätvärdena visar tecken på återhämtning, men din egen notering säger att du inte känner dig helt på topp."
                : "Både din egen notering och nattens signaler talar för att vara varsam med belastningen."
            } ?? "Du har berättat hur du känner dig. VITAL saknar samtidigt tillräckliga nattvärden för en fullständig återhämtningsbedömning."
            return (headline, detail, "Välj aktivitet efter dagsformen – en lugn promenad kan räcka gott.", "heart.text.square.fill", VITALPalette.amber)
        }
        guard let score else {
            return ("Vi samlar fortfarande in underlag.", "VITAL kan ännu inte väga samman sömn, HRV och vilopuls mot din personliga baslinje. Saknade värden ska inte tolkas som vare sig bra eller dåliga.", "Följ hur du känner dig och invänta fler mätningar innan du drar slutsatser om träningsformen.", "waveform.path.ecg", VITALPalette.steel)
        }
        if score >= 80 {
            let opener = goodOpeners[variation % goodOpeners.count]
            return ("Bra förutsättningar för dagen.", "\(opener) Nattens återhämtningsestimat är \(score) av 100.", "Ett träningspass kan vara ett alternativ om även din egen energi och dagsform känns bra.", "sun.max.fill", VITALPalette.lime)
        }
        if score >= 55 {
            return ("En balanserad dag passar bra.", "Återhämtningsestimatet är \(score) av 100. Signalerna ger en blandad bild – varken ett tydligt grönt ljus eller skäl att dra stora slutsatser.", "Håll dig till en lagom belastning och justera efter hur kroppen svarar.", "scale.3d", VITALPalette.lavender)
        }
        let opener = carefulOpeners[variation % carefulOpeners.count]
        return ("Prioritera återhämtning.", "\(opener) Nattens återhämtningsestimat är \(score) av 100.", "Överväg lättare rörelse idag och prioritera sömn och återhämtning.", "leaf.fill", VITALPalette.amber)
    }

    private func heroFact(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.vital(size: 12, weight: .bold)).tracking(0.8).foregroundStyle(VITALPalette.steel)
            Text(value).font(.vital(size: 17.4, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(VITALPalette.paper)
        }
    }

    private var moodCheckIn: some View {
        let choices: [(String, String, String)] = [
            ("low", "😔", "Tungt"),
            ("okay", "😐", "Okej"),
            ("good", "🙂", "Bra"),
            ("great", "😁", "Toppen")
        ]
        return VStack(alignment: .leading, spacing: 11) {
            HStack {
                sectionHeading("HUR KÄNNS DAGEN?", subtitle: "En snabb daglig notering")
                Spacer()
                if !selectedMood.isEmpty {
                    Text("SPARAT").font(.vital(size: 12, weight: .heavy)).tracking(1)
                        .foregroundStyle(VITALPalette.lime)
                }
            }
            HStack(spacing: 8) {
                ForEach(choices, id: \.0) { choice in
                    let isSelected = selectedMood == choice.0
                    Button {
                        selectedMood = choice.0
                        savedMood = choice.0
                        savedMoodDate = Calendar.current.startOfDay(for: Date()).formatted(.iso8601.year().month().day().dateSeparator(.dash))
                    } label: {
                        VStack(spacing: 6) {
                            Text(choice.1).font(.vital(size: 31))
                            Text(choice.2).font(.vital(size: 12, weight: .semibold))
                                .foregroundStyle(isSelected ? VITALPalette.lime : VITALPalette.steel)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(isSelected ? VITALPalette.lime.opacity(0.12) : VITALPalette.panel,
                                    in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(isSelected ? VITALPalette.lime.opacity(0.55) : Color.white.opacity(0.055), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Humör: \(choice.2)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .padding(15)
        .background(VITALPalette.panel.opacity(0.65), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.white.opacity(0.055), lineWidth: 1))
    }

    private func restoreTodayMood() {
        let today = Calendar.current.startOfDay(for: Date()).formatted(.iso8601.year().month().day().dateSeparator(.dash))
        selectedMood = savedMoodDate == today ? savedMood : ""
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
            Image(systemName: symbol).font(.vital(size: 17.4, weight: .semibold)).foregroundStyle(tint)
                .frame(width: 30, height: 30).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Text(title.uppercased()).font(.vital(size: 12, weight: .heavy)).tracking(1).foregroundStyle(VITALPalette.steel)
            Text(value).font(.vital(size: 19.9, weight: .bold, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(VITALPalette.paper)
            Text(detail).font(.vital(size: 12, weight: .medium)).foregroundStyle(VITALPalette.steel).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading).padding(11)
        .background(LinearGradient(colors: [Color(hex: 0x192B3C), VITALPalette.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.075), lineWidth: 1))
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
                    Image(systemName: "battery.100percent").font(.vital(size: 27.3, weight: .medium)).foregroundStyle(VITALPalette.lavender)
                }.frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 5) {
                    Text(battery?.score.map(String.init) ?? "—").font(.vital(size: 39.7, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(VITALPalette.paper)
                    Text(battery?.explanation ?? "Inväntar tillräckliga mätningar").font(.vital(size: 13.6)).foregroundStyle(VITALPalette.steel).fixedSize(horizontal: false, vertical: true)
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
                .font(.vital(size: 12, weight: .medium)).foregroundStyle(VITALPalette.steel)
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
                            .font(.vital(size: 24.8, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1).foregroundStyle(VITALPalette.paper)
                        Text("STEG").font(.vital(size: 12, weight: .heavy)).tracking(1).foregroundStyle(VITALPalette.steel)
                    }
                }.frame(width: 88, height: 88)
                VStack(alignment: .leading, spacing: 5) {
                    Text(steps == nil ? "Inväntar data" : "\(Int(progress * 100)) % av målet")
                        .font(.vital(size: 22.4, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.paper)
                    Text("8 000 steg per dag").font(.vital(size: 13.6)).foregroundStyle(VITALPalette.steel)
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
                Text(title).font(.vital(size: 14.9, weight: .semibold)).foregroundStyle(VITALPalette.paper)
                Spacer()
                Text(value.map { "\(String(format: "%.1f", $0)) \(suffix)" } ?? "Samlar data")
                    .font(.vital(size: 13.6, weight: .bold, design: .rounded)).foregroundStyle(value == nil ? VITALPalette.amber : VITALPalette.lime)
                Text("\(days)/14").font(.vital(size: 12, weight: .medium, design: .rounded)).foregroundStyle(VITALPalette.steel)
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
        .font(.vital(size: 12, weight: .bold, design: .rounded)).tracking(0.6).foregroundStyle(VITALPalette.steel)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.vital(size: 12, weight: .heavy, design: .rounded)).tracking(1.4).foregroundStyle(VITALPalette.lime)
            Text(subtitle).font(.vital(size: 13.6, weight: .medium)).foregroundStyle(VITALPalette.steel)
        }
    }

    private func miniStat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.vital(size: 12, weight: .heavy)).tracking(0.5).foregroundStyle(VITALPalette.steel)
            Text(value).font(.vital(size: 13.6, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.paper).lineLimit(1).minimumScaleFactor(0.7)
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


/// Subtle layered wave motif shared by the approved VITAL Midnight visual language.
private struct VITALWaveShape: Shape {
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.48))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.34),
            control1: CGPoint(x: rect.width * 0.28, y: rect.height * (0.04 + phase * 0.2)),
            control2: CGPoint(x: rect.width * 0.64, y: rect.height * (0.94 - phase * 0.18))
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
