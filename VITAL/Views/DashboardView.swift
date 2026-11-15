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
                    reportsSection
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
                HStack(spacing: 18) {
                    ScoreRing(score: result.score, tint: VITALPalette.teal, size: 112)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(result.score.map { "\($0)" } ?? "—")
                            .font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                        Text("av 100").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                        Text(result.score == nil ? baselineStatus : "Personlig återhämtningsnivå")
                            .font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                }
                if let score = result.score {
                    componentRow("Sömn", value: result.sleepComponent)
                    componentRow("HRV", value: result.hrvComponent)
                    componentRow("Vilopuls", value: result.restingPulseComponent)
                } else {
                    HStack(spacing: 6) {
                        Circle().fill(VITALPalette.amber).frame(width: 6, height: 6)
                        Text("Bygger personlig baslinje · \(baselineStatus)")
                    }.font(.caption).foregroundStyle(VITALPalette.muted)
                }
                Text("Preliminär uppskattning")
                    .font(.caption2).foregroundStyle(VITALPalette.amber)
            }
        }
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
                    Label("Skapas när huvudsömnen är registrerad", systemImage: "moon.zzz")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
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
                    reportRow("Senaste vilopuls", value: report.restingHeartRateBPM.map { "\(Int($0.rounded())) bpm" } ?? "—")
                    reportRow("Kroppsbatteri", value: report.bodyBatteryScore.map { "\($0) / 100" } ?? "—")
                    Text("Fryst rapport · fångad vid första uppdateringen efter kl. 21:00.")
                        .font(.caption2).foregroundStyle(VITALPalette.muted)
                } else {
                    Label("Påminnelse kl. 21:00", systemImage: "bell")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                }
            }
        }
    }

    private var reportsSection: some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                morningReportCard
                eveningReportCard
                reportHistoryCard
            }.padding(.top, 8)
        } label: {
            HStack {
                Label("Rapporter", systemImage: "doc.text")
                    .font(.headline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                Spacer()
                Text("Morgon · kväll").font(.caption).foregroundStyle(VITALPalette.muted)
            }.padding(.vertical, 5)
        }
        .tint(VITALPalette.teal)
        .padding(16)
        .background(VITALPalette.midnight, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                                    Text(report.localDayDisplayText)
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
                Text(battery?.score == nil ? "Inväntar tillräckligt underlag" : "Dagens beräknade energinivå")
                    .font(.caption).foregroundStyle(VITALPalette.muted)
                if let battery, battery.score != nil {
                    HStack {
                        Label("\(battery.heartRateSampleCount) pulsmätningar", systemImage: "heart")
                        Spacer()
                        Text("\(Int(battery.activeEnergyKcal.rounded())) kcal aktiv energi")
                    }.font(.caption2).foregroundStyle(VITALPalette.teal)
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
                HStack {
                    Label("Sömn i bakgrunden", systemImage: "moon.zzz").foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text(health.backgroundSleepDeliveryEnabled ? "Aktiverad" : "Ej bekräftad")
                        .font(.caption).foregroundStyle(health.backgroundSleepDeliveryEnabled ? VITALPalette.teal : VITALPalette.amber)
                }
                HStack {
                    Label("Kvällspåminnelse", systemImage: "bell").foregroundStyle(VITALPalette.cloud)
                    Spacer(); Text(health.eveningNotificationStatus)
                        .font(.caption).foregroundStyle(health.eveningNotificationStatus == "Aktiverad" ? VITALPalette.teal : VITALPalette.amber)
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
