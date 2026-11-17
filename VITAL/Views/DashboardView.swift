import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var health: HealthKitStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var moodJournal = MoodJournalStore()
    @State private var showingMoodCheckIn = false
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
                    moodJournalCard
                    habitsCard
                }.padding(.horizontal, VITALSpacing.page).padding(.top, 12).padding(.bottom, 28)
            }
        }
        .task { if !health.authorizationRequested { await health.requestAccessAndRefresh() } }
        .refreshable { await health.refresh() }
        .sheet(isPresented: $showingMoodCheckIn) {
            MoodCheckInSheet(journal: moodJournal)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
        let recovery = health.snapshot.recoveryResult
        let guidance = RecoveryGuidancePolicy.evaluate(sleep: recovery.sleepComponent, hrv: recovery.hrvComponent, restingPulse: recovery.restingPulseComponent)
        let statusTint = guidance.hasAttentionSignal ? VITALPalette.amber : VITALPalette.teal
        return VITALCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NATTENS ÅTERHÄMTNING").font(.subheadline.weight(.semibold)).tracking(0.7).foregroundStyle(VITALPalette.muted)
                        Text("Jämfört med din personliga baslinje").font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                    Spacer()
                    Image(systemName: "moon.stars.fill").font(.title3.weight(.semibold)).foregroundStyle(statusTint)
                        .frame(width: 42, height: 42).background(statusTint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                }
                HStack(spacing: 18) {
                    ScoreRing(score: recovery.score, tint: statusTint, size: 112)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recovery.score.map(String.init) ?? "—").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud).monospacedDigit()
                        Text("AV 100").font(.caption.weight(.bold)).tracking(0.8).foregroundStyle(statusTint)
                        Text(guidance.title).font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                    }
                }
                Text(recovery.score == nil ? recovery.explanation : guidance.detail).font(.subheadline).foregroundStyle(VITALPalette.muted).fixedSize(horizontal: false, vertical: true)
                if !guidance.attentionSignals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("VÄRT ATT UPPMÄRKSAMMA", systemImage: "exclamationmark.circle").font(.caption2.weight(.bold)).tracking(0.6).foregroundStyle(VITALPalette.amber)
                        ForEach(guidance.attentionSignals, id: \.self) { signal in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(VITALPalette.amber).frame(width: 6, height: 6).padding(.top, 6)
                                Text(signal).font(.caption).foregroundStyle(VITALPalette.cloud)
                            }
                        }
                    }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(VITALPalette.amber.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                }
                HStack(spacing: 10) {
                    Image(systemName: guidance.hasAttentionSignal ? "leaf" : "figure.walk").font(.headline).foregroundStyle(statusTint).frame(width: 34, height: 34).background(statusTint.opacity(0.13), in: RoundedRectangle(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DAGENS RÅD").font(.caption2.weight(.bold)).tracking(0.7).foregroundStyle(statusTint)
                        Text(guidance.recommendation).font(.subheadline.weight(.medium)).foregroundStyle(VITALPalette.cloud).fixedSize(horizontal: false, vertical: true)
                    }
                }.padding(13).frame(maxWidth: .infinity, alignment: .leading).background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 16))
                HStack(spacing: 7) {
                    Image(systemName: "moon.stars")
                    Text(health.snapshot.sleepText)
                    Spacer()
                    Text("HRV")
                    Text(health.snapshot.overnightHRV.map { "\(Int($0.rounded())) ms" } ?? "—")
                    Text("·")
                    Text("Vilopuls")
                    Text(health.snapshot.overnightRestingHeartRate.map { "\(Int($0.rounded())) bpm" } ?? "—")
                }.font(.caption.weight(.medium)).foregroundStyle(VITALPalette.muted)
                Text("Över natten · Kroppsbatteriet följer dagens förändringar separat").font(.caption2).foregroundStyle(VITALPalette.muted)
            }
        }
    }
    private static func formatSleepDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration) / 60)
        return "\(totalMinutes / 60) h \(String(format: "%02d", totalMinutes % 60)) min"
    }
    private var moodJournalCard: some View {
        let latest = moodJournal.entries.last
        let recent = Array(moodJournal.entries.suffix(7))
        return VITALCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Hur mår du?", systemImage: "face.smiling")
                        .font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                    Spacer()
                    Button("Registrera") { showingMoodCheckIn = true }
                        .font(.subheadline.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                }
                if let latest {
                    HStack(spacing: 12) {
                        Image(systemName: latest.mood.symbol)
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(latest.mood.color)
                            .frame(width: 54, height: 54)
                            .background(latest.mood.color.opacity(0.14), in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(latest.mood.title).font(.title3.bold()).foregroundStyle(VITALPalette.cloud)
                            Text("Senast registrerat · \(latest.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(VITALPalette.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(latest.intensity)/5").font(.title2.bold().monospacedDigit()).foregroundStyle(latest.mood.color)
                            Text("intensitet").font(.caption2).foregroundStyle(VITALPalette.muted)
                        }
                    }
                    if recent.count > 1 {
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(recent) { entry in
                                VStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(entry.mood.color.gradient)
                                        .frame(height: CGFloat(entry.mood.level) * 13 + 8)
                                    Text(entry.date.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2).foregroundStyle(VITALPalette.muted)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 92, alignment: .bottom)
                        .padding(.horizontal, 4)
                        Text("Senaste registreringar")
                            .font(.caption2).foregroundStyle(VITALPalette.muted)
                    } else {
                        Text("Din måendekurva visas här när du har fler registreringar.")
                            .font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                    if !latest.note.isEmpty {
                        Text("”\(latest.note)”").font(.subheadline).italic().foregroundStyle(VITALPalette.muted)
                            .lineLimit(2)
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 28)).foregroundStyle(VITALPalette.teal)
                            .frame(width: 54, height: 54)
                            .background(VITALPalette.teal.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ditt mående").font(.headline).foregroundStyle(VITALPalette.cloud)
                            Text("Registrera dagens läge").font(.caption).foregroundStyle(VITALPalette.muted)
                        }
                    }
                    Button { showingMoodCheckIn = true } label: {
                        Label("Hur mår du idag?", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(VITALPalette.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
                    }.foregroundStyle(VITALPalette.teal)
                }
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
            MetricCard(title: "SÖMN", value: health.snapshot.sleepText, detail: health.snapshot.sleepDuration == nil ? "Ingen sömndata" : "Senaste huvudsömn", accent: VITALPalette.violet)
            MetricCard(title: "NATT-HRV", value: health.snapshot.overnightHRV.map { "\(Int($0.rounded())) ms" } ?? "—", detail: health.snapshot.overnightHRV == nil ? "Ingen nattmätning" : "Under sömn", accent: VITALPalette.teal)
            MetricCard(title: "NATTPULS", value: health.snapshot.overnightRestingHeartRate.map { "\(Int($0.rounded())) bpm" } ?? "—", detail: health.snapshot.overnightRestingHeartRate == nil ? "Ingen nattmätning" : "Under sömn", accent: VITALPalette.teal)
            MetricCard(title: "SENASTE HRV", value: health.snapshot.hrvText, detail: health.snapshot.hrv == nil ? "Ingen mätning" : "Senaste registrering", accent: VITALPalette.violet)
        }
    }
    private var energyCard: some View {
        let battery = health.snapshot.bodyBattery
        return VITALCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    ScoreRing(score: battery?.score, tint: VITALPalette.violet, size: 92)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Kroppsbatteri").font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(battery?.score.map { String($0) } ?? "—")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(VITALPalette.violet).monospacedDigit()
                            Text("/ 100").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.muted)
                        }
                    }
                    Spacer()
                }
                if let battery, battery.score == nil {
                    Text(battery.explanation)
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Dagens beräknade energinivå")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                }
                if let battery, battery.score != nil {
                    HStack(spacing: 8) {
                        Label("\(battery.heartRateSampleCount) pulsmätningar", systemImage: "heart")
                        Spacer(minLength: 4)
                        Text("\(Int(battery.activeEnergyKcal.rounded())) kcal aktivitet")
                    }.font(.caption2).foregroundStyle(VITALPalette.teal)
                    HStack {
                        Label("Återhämtning i vila", systemImage: "leaf")
                        Spacer()
                        Text("+\(Int(battery.recoveryGain.rounded()))")
                            .monospacedDigit()
                    }.font(.caption2.weight(.medium)).foregroundStyle(VITALPalette.teal)
                }
                Text("Preliminär uppskattning")
                    .font(.caption2).foregroundStyle(VITALPalette.amber)
            }
        }
    }
    private var activityCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 13) {
                Text("Dagens rörelse").font(.headline).foregroundStyle(VITALPalette.cloud)
                HStack(spacing: 20) {
                    ActivityRing(progress: min((health.snapshot.steps ?? 0) / 8000, 1), hasData: health.snapshot.steps != nil)
                        .frame(width: 112, height: 112)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(health.snapshot.stepsText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(VITALPalette.cloud).monospacedDigit()
                            .minimumScaleFactor(0.75).lineLimit(1)
                        Text("steg idag").font(.subheadline).foregroundStyle(VITALPalette.muted)
                        Text("Mål 8 000").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                    }
                    Spacer(minLength: 0)
                }
                HStack {
                    Label(health.snapshot.steps == nil ? "Inväntar data" : "Apple Hälsa", systemImage: "figure.walk")
                    Spacer()
                    if let steps = health.snapshot.steps {
                        Text("\(Int(min(steps / 8000, 1) * 100)) % av målet")
                    }
                }.font(.caption).foregroundStyle(VITALPalette.muted)

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
                HStack {
                    Label("Sömn i bakgrunden", systemImage: "moon.zzz").foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text(health.backgroundSleepDeliveryEnabled ? "Aktiverad" : "Ej bekräftad")
                        .font(.caption).foregroundStyle(health.backgroundSleepDeliveryEnabled ? VITALPalette.teal : VITALPalette.amber)
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
    private var symbol: String {
        switch title {
        case "SÖMN": "moon.stars.fill"
        case "NATT-HRV", "SENASTE HRV": "waveform.path.ecg"
        case "NATTPULS": "heart.fill"
        default: "heart.text.square"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
                Spacer()
                Circle().fill(accent.opacity(0.85)).frame(width: 6, height: 6)
            }
            Text(title).font(.caption.weight(.semibold)).tracking(0.5).foregroundStyle(VITALPalette.muted)
            Text(value).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud).lineLimit(1).minimumScaleFactor(0.75)
            Text(detail).font(.caption2).foregroundStyle(accent).lineLimit(1)
        }.frame(maxWidth: .infinity, minHeight: 132, alignment: .leading).padding(15)
            .background(
                LinearGradient(colors: [VITALPalette.midnight, VITALPalette.midnight.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2).fill(accent.opacity(0.8)).frame(height: 2).padding(.horizontal, 18)
            }
    }
}


private enum MoodState: String, Codable, CaseIterable, Identifiable {
    case great, good, okay, low, stressed, sick, pain

    var id: String { rawValue }
    var title: String {
        switch self {
        case .great: "Full av energi"
        case .good: "Bra"
        case .okay: "Okej"
        case .low: "Låg / nedstämd"
        case .stressed: "Stressad"
        case .sick: "Sjuk"
        case .pain: "Smärta / värk"
        }
    }
    var symbol: String {
        switch self {
        case .great: "sun.max.fill"
        case .good: "face.smiling.fill"
        case .okay: "face.neutral"
        case .low: "cloud.fill"
        case .stressed: "bolt.heart.fill"
        case .sick: "cross.case.fill"
        case .pain: "bandage.fill"
        }
    }
    var level: Int {
        switch self {
        case .great: 5
        case .good: 4
        case .okay: 3
        case .low, .stressed: 2
        case .sick, .pain: 1
        }
    }
    var color: Color {
        switch self {
        case .great: .green
        case .good: VITALPalette.teal
        case .okay: VITALPalette.violet
        case .low: .orange
        case .stressed: .yellow
        case .sick, .pain: .red
        }
    }
}

private struct MoodEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var mood: MoodState
    var intensity: Int
    var note: String
}

@MainActor
private final class MoodJournalStore: ObservableObject {
    @Published private(set) var entries: [MoodEntry] = []
    private let key = "vital.moodJournal.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = saved.sorted { $0.date < $1.date }
        }
    }

    func add(mood: MoodState, intensity: Int, note: String) {
        let entry = MoodEntry(date: .now, mood: mood, intensity: intensity, note: note)
        entries.append(entry)
        entries.sort { $0.date < $1.date }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private struct MoodCheckInSheet: View {
    @ObservedObject var journal: MoodJournalStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodState = .good
    @State private var intensity = 3
    @State private var note = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hur mår du idag?").font(.title2.bold()).foregroundStyle(VITALPalette.cloud)
                            Text("Din registrering sparas privat på den här enheten och hjälper dig att följa mönster över tid.")
                                .font(.subheadline).foregroundStyle(VITALPalette.muted)
                        }
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(MoodState.allCases) { mood in
                                Button { selectedMood = mood } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: mood.symbol).foregroundStyle(mood.color)
                                        Text(mood.title).font(.subheadline.weight(.semibold))
                                            .foregroundStyle(VITALPalette.cloud).multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                        if selectedMood == mood { Image(systemName: "checkmark.circle.fill").foregroundStyle(VITALPalette.teal) }
                                    }
                                    .padding(13).frame(minHeight: 66)
                                    .background(VITALPalette.midnight, in: RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(selectedMood == mood ? VITALPalette.teal : mood.color.opacity(0.25), lineWidth: selectedMood == mood ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Hur starkt känns det?").font(.headline).foregroundStyle(VITALPalette.cloud)
                                Spacer()
                                Text("\(intensity)/5").font(.headline.monospacedDigit()).foregroundStyle(VITALPalette.teal)
                            }
                            Slider(value: Binding(get: { Double(intensity) }, set: { intensity = Int($0) }), in: 1...5, step: 1).tint(VITALPalette.teal)
                            HStack { Text("Milt"); Spacer(); Text("Måttligt"); Spacer(); Text("Mycket starkt") }
                                .font(.caption2).foregroundStyle(VITALPalette.muted)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anteckningar").font(.headline).foregroundStyle(VITALPalette.cloud)
                            TextField("T.ex. pigg efter bra sömn, huvudvärk eller illamående…", text: $note, axis: .vertical)
                                .lineLimit(3...5).padding(12)
                                .background(VITALPalette.midnight, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(VITALPalette.cloud)
                        }
                        Button {
                            journal.add(mood: selectedMood, intensity: intensity, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        } label: {
                            Text("Spara dagens mående").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(VITALPalette.teal, in: RoundedRectangle(cornerRadius: 15))
                                .foregroundStyle(VITALPalette.midnight)
                        }
                    }.padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Avbryt") { dismiss() }.foregroundStyle(VITALPalette.teal) }
                ToolbarItem(placement: .principal) { Text("Måendedagbok").font(.headline).foregroundStyle(VITALPalette.cloud) }
            }
        }
        .tint(VITALPalette.teal)
    }
}


private struct ActivityRing: View {
    let progress: Double
    let hasData: Bool
    var body: some View {
        ZStack {
            Circle().stroke(VITALPalette.track, lineWidth: 11)
            Circle()
                .trim(from: 0, to: hasData ? progress : 0)
                .stroke(
                    AngularGradient(colors: [VITALPalette.teal, Color(hex: 0x4FA8C8), VITALPalette.teal], center: .center),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Image(systemName: "figure.walk").font(.system(size: 20, weight: .semibold)).foregroundStyle(VITALPalette.teal)
                Text(hasData ? "\(Int(progress * 100))%" : "—")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(VITALPalette.cloud).monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hasData ? "Stegmål \(Int(progress * 100)) procent" : "Stegdata saknas")
    }
}

private struct ScoreRing: View {
    let score: Int?
    let tint: Color
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle().stroke(VITALPalette.track, lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(score ?? 0, 100))) / 100)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if score == nil {
                Image(systemName: "minus").font(.title2.bold()).foregroundStyle(VITALPalette.muted)
            } else {
                Image(systemName: "sparkles").font(.system(size: 17, weight: .semibold)).foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score.map { "\($0) av 100" } ?? "Inget värde")
    }
}
