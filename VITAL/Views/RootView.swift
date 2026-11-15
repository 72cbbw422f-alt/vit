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
                                    Chart {
                                        ForEach(Array(recoveryReports.enumerated()), id: \.element.id) { item in
                                            BarMark(
                                                x: .value("Dag", item.offset),
                                                y: .value("Återhämtning", item.element.recoveryScore ?? 0)
                                            )
                                            .foregroundStyle(VITALPalette.teal.gradient)
                                            .cornerRadius(5)
                                        }
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
    @StateObject private var bloodPressure = BloodPressureJournal()
    @State private var showingBloodPressureEntry = false
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
                        bloodPressureCard
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

    private var bloodPressureCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Label("Blodtryck", systemImage: "heart.text.square")
                        .font(.headline).foregroundStyle(VITALPalette.cloud)
                    Spacer()
                    Button { showingBloodPressureEntry = true } label: {
                        Label("Lägg till", systemImage: "plus")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                    }
                }
                if let latest = bloodPressure.entries.first {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(latest.systolic)/\(latest.diastolic)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(VITALPalette.cloud).monospacedDigit()
                        Text("mmHg").font(.caption).foregroundStyle(VITALPalette.muted)
                        Spacer()
                        if let pulse = latest.pulse {
                            Text("\(pulse) bpm").font(.subheadline.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                        }
                    }
                    Text("Senast · \(latest.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                    if bloodPressure.entries.count > 1 {
                        Chart(Array(bloodPressure.entries.prefix(10).reversed()), id: \.id) { entry in
                            LineMark(x: .value("Mätning", entry.date), y: .value("Systoliskt", entry.systolic))
                                .foregroundStyle(VITALPalette.teal).symbol(Circle())
                            LineMark(x: .value("Mätning", entry.date), y: .value("Diastoliskt", entry.diastolic))
                                .foregroundStyle(VITALPalette.violet).symbol(Circle())
                        }
                        .chartLegend(position: .bottom)
                        .chartYAxisLabel("mmHg")
                        .frame(height: 150)
                    }
                    ShareLink(item: bloodPressure.doctorSummary) {
                        Label("Dela sammanställning med läkaren", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(VITALPalette.teal.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                    }.foregroundStyle(VITALPalette.teal)
                } else {
                    EmptyChartState(symbol: "heart.text.square", title: "Ingen blodtryckshistorik", detail: "Lägg in dina mätningar för att följa utvecklingen över tid.")
                }
                Text("Registrerade värden är en loggbok, inte en diagnos.")
                    .font(.caption2).foregroundStyle(VITALPalette.muted)
            }
        }
        .sheet(isPresented: $showingBloodPressureEntry) {
            BloodPressureEntrySheet(journal: bloodPressure)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct BloodPressureEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let systolic: Int
    let diastolic: Int
    let pulse: Int?
    let note: String
    init(date: Date = .now, systolic: Int, diastolic: Int, pulse: Int?, note: String) {
        self.id = UUID(); self.date = date; self.systolic = systolic
        self.diastolic = diastolic; self.pulse = pulse; self.note = note
    }
}
@MainActor private final class BloodPressureJournal: ObservableObject {
    @Published private(set) var entries: [BloodPressureEntry] = []
    private let key = "vital.bloodPressureJournal.v1"
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([BloodPressureEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    func add(systolic: Int, diastolic: Int, pulse: Int?, note: String) {
        entries.append(BloodPressureEntry(systolic: systolic, diastolic: diastolic, pulse: pulse, note: note))
        entries.sort { $0.date > $1.date }
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: key) }
    }
    var doctorSummary: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.dateStyle = .medium; formatter.timeStyle = .short
        let lines = entries.prefix(100).map { entry in
            let pulse = entry.pulse.map { " · Puls \($0) bpm" } ?? ""
            let note = entry.note.isEmpty ? "" : " · \(entry.note)"
            return "\(formatter.string(from: entry.date)): \(entry.systolic)/\(entry.diastolic) mmHg\(pulse)\(note)"
        }
        return (["VITAL – BLODTRYCKSLOGG", "Registrerade mätningar (nyaste först)", ""] + lines).joined(separator: "\n")
    }
}
private struct BloodPressureEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: BloodPressureJournal
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var pulse = ""
    @State private var note = ""
    private var valid: Bool {
        guard let s = Int(systolic), let d = Int(diastolic) else { return false }
        return (60...260).contains(s) && (30...160).contains(d)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Blodtryck") {
                    TextField("Systoliskt (övre)", text: $systolic).keyboardType(.numberPad)
                    TextField("Diastoliskt (undre)", text: $diastolic).keyboardType(.numberPad)
                    TextField("Puls (valfritt)", text: $pulse).keyboardType(.numberPad)
                }
                Section("Anteckning") {
                    TextField("T.ex. morgon, kväll eller efter vila", text: $note, axis: .vertical)
                }
                Section {
                    Text("Ange värdena från mätaren. Skriv gärna om mätningen gjordes sittande efter vila eller om något särskilt påverkade den.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(VITALPalette.surface)
            .navigationTitle("Ny mätning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        journal.add(systolic: Int(systolic)!, diastolic: Int(diastolic)!, pulse: Int(pulse), note: note)
                        dismiss()
                    }.disabled(!valid || (!pulse.isEmpty && Int(pulse) == nil))
                }
            }
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
                Text(value).font(.system(.title2, design: .rounded).bold()).foregroundStyle(VITALPalette.cloud).minimumScaleFactor(0.7).lineLimit(1)
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
            Text(value).font(.system(.title2, design: .rounded).bold()).foregroundStyle(tint).minimumScaleFactor(0.7).lineLimit(1)
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
