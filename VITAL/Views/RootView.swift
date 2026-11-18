import SwiftUI
import Charts
import UserNotifications
import PhotosUI
import UIKit

/// Decodes locally stored journal data and preserves an unreadable payload for recovery.
private func decodeJournal<T: Decodable>(_ type: T.Type, key: String) -> T? {
    let defaults = UserDefaults.standard
    guard let data = defaults.data(forKey: key) else { return nil }
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch {
        let backupKey = "\(key).recoveryBackup.v1"
        if defaults.data(forKey: backupKey) == nil {
            defaults.set(data, forKey: backupKey)
        }
        return nil
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            VITALDashboardView().tabItem { Label("Idag", systemImage: "house.fill") }
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
                        NavigationLink {
                            ReportHistoryView()
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(VITALPalette.teal)
                                    .frame(width: 44, height: 44)
                                    .background(VITALPalette.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Rapporthistorik").font(.headline).foregroundStyle(VITALPalette.cloud)
                                    Text("\(health.reportHistory.count) sparade rapporter · frysta ögonblicksbilder")
                                        .font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(VITALPalette.muted)
                            }
                            .padding(14)
                            .background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        VITALCard {
                            let recovery = health.snapshot.recoveryResult
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Aktuell återhämtning", systemImage: "waveform.path.ecg")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(recovery.score.map(String.init) ?? "—")
                                        .font(.system(size: 38, weight: .bold, design: .rounded))
                                        .foregroundStyle(VITALPalette.teal).monospacedDigit()
                                    Text("av 100 · senaste sömn")
                                        .font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                                Text(recovery.explanation)
                                    .font(.caption).foregroundStyle(VITALPalette.muted)
                                Divider().overlay(VITALPalette.track)
                                baselineRow("Sömn", days: health.snapshot.sleepBaseline?.validDays ?? 0)
                                baselineRow("HRV", days: health.snapshot.hrvBaseline?.validDays ?? 0)
                                baselineRow("Vilopuls", days: health.snapshot.restingHeartRateBaseline?.validDays ?? 0)
                                Text("Värdet räknas om när VITAL hämtar nya data från Apple Hälsa. Baslinjen bygger på tillgängliga mätningar från de senaste 30 dagarna.")
                                    .font(.caption2).foregroundStyle(VITALPalette.muted)
                            }
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Historisk återhämtning", systemImage: "clock.arrow.circlepath")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                if recoveryReports.isEmpty {
                                    EmptyChartState(symbol: "chart.xyaxis.line", title: "Ingen trend ännu", detail: "Äldre sparade morgonvärden visas här. Den aktuella återhämtningen visas separat ovan.")
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
                                    Text("\(recoveryReports.count) äldre sparade morgonvärden")
                                        .font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            InsightMetric(title: "Sömn", value: health.snapshot.sleepText, symbol: "moon.stars.fill", tint: VITALPalette.violet)
                            InsightMetric(title: "HRV", value: health.snapshot.hrvText, symbol: "waveform.path", tint: VITALPalette.teal)
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Din normala nivå", systemImage: "person.crop.circle")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                baselineValueRow("Sömn", value: health.snapshot.sleepBaseline?.median, suffix: "h", decimals: 1)
                                baselineValueRow("HRV", value: health.snapshot.hrvBaseline?.median, suffix: "ms", decimals: 0)
                                baselineValueRow("Vilopuls", value: health.snapshot.restingHeartRateBaseline?.median, suffix: "bpm", decimals: 0)
                                Text("Median från de senaste 30 dagarna. Kräver minst 14 giltiga dagar per mätvärde.")
                                    .font(.caption2).foregroundStyle(VITALPalette.muted)
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
    private func baselineValueRow(_ title: String, value: Double?, suffix: String, decimals: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            if let value, value.isFinite, value > 0 {
                Text("\(String(format: "%.*f", decimals, value)) \(suffix)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(VITALPalette.cloud)
            } else {
                Text("Samlar data").font(.subheadline).foregroundStyle(VITALPalette.amber)
            }
        }.padding(.vertical, 3)
    }

    private func baselineRow(_ title: String, days: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text("\(days) giltiga dagar").font(.subheadline.monospacedDigit()).foregroundStyle(days >= 14 ? VITALPalette.teal : VITALPalette.amber)
        }.padding(.vertical, 5)
    }
}

private struct ReportHistoryView: View {
    @EnvironmentObject private var health: HealthKitStore

    var body: some View {
        ZStack {
            VITALPalette.surface.ignoresSafeArea()
            if health.reportHistory.isEmpty {
                ContentUnavailableView(
                    "Inga rapporter ännu",
                    systemImage: "doc.text",
                    description: Text("När VITAL har fångat morgon- och kvällsrapporter visas de här. Rapporternas värden ändras inte efter att de sparats.")
                )
                .foregroundStyle(VITALPalette.cloud)
            } else {
                ScrollView {
                    LazyVStack(spacing: 11) {
                        ForEach(health.reportHistory.sorted { $0.capturedAt > $1.capturedAt }) { report in
                            NavigationLink {
                                ReportSnapshotDetailView(report: report)
                            } label: {
                                HStack(spacing: 13) {
                                    VStack(spacing: 4) {
                                        Image(systemName: report.kind == .morning ? "sunrise.fill" : "moon.stars.fill")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text(report.capturedAt.formatted(.dateTime.hour().minute()))
                                            .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                                    }
                                    .foregroundStyle(report.kind == .morning ? VITALPalette.teal : VITALPalette.violet)
                                    .frame(width: 54, height: 58)
                                    .background((report.kind == .morning ? VITALPalette.teal : VITALPalette.violet).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(report.localDayDisplayText).font(.headline).foregroundStyle(VITALPalette.cloud)
                                        Text(report.kind == .morning ? "Morgonrapport" : "Kvällsrapport")
                                            .font(.caption).foregroundStyle(VITALPalette.muted)
                                        Text("Sparad ögonblicksbild").font(.system(size: 10, weight: .medium)).foregroundStyle(VITALPalette.muted)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(report.recoveryScore.map(String.init) ?? "—")
                                            .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                                            .foregroundStyle(VITALPalette.teal)
                                        Text("ÅTERHÄMTNING").font(.system(size: 8, weight: .heavy)).tracking(0.5).foregroundStyle(VITALPalette.muted)
                                    }
                                    Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(VITALPalette.muted)
                                }
                                .padding(13)
                                .background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(VITALSpacing.page)
                }
            }
        }
        .navigationTitle("Rapporthistorik")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReportSnapshotDetailView: View {
    let report: DailyReportSnapshot

    var body: some View {
        ZStack {
            VITALPalette.surface.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(report.kind == .morning ? "MORGONRAPPORT" : "KVÄLLSRAPPORT")
                            .font(.caption.weight(.heavy)).tracking(1.3).foregroundStyle(VITALPalette.teal)
                        Text(report.localDayDisplayText)
                            .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                        Text("Fångad \(report.capturedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                    VITALCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(report.kind == .morning ? "NATTENS ÅTERHÄMTNING" : "ÅTERHÄMTNING VID KVÄLLSRAPPORT").font(.caption.weight(.bold)).tracking(0.7).foregroundStyle(VITALPalette.muted)
                                Text(report.recoveryScore.map { "\($0) / 100" } ?? "Saknar underlag")
                                    .font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.teal)
                            }
                            Spacer()
                            Image(systemName: "moon.stars.fill").font(.system(size: 32)).foregroundStyle(VITALPalette.teal)
                        }
                        Divider().overlay(VITALPalette.track)
                        reportComponent("Sömn", score: report.sleepComponentScore)
                        reportComponent("HRV", score: report.hrvComponentScore)
                        reportComponent("Vilopuls", score: report.restingPulseComponentScore)
                    }
                    VITALCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Text(report.kind == .morning ? "SPARADE MÄTVÄRDEN" : "DAGENS BELASTNING OCH MÄTVÄRDEN").font(.caption.weight(.heavy)).tracking(0.8).foregroundStyle(VITALPalette.muted)
                            savedMetric("Sömn", value: report.sleepDurationSeconds.map { duration in
                                let minutes = Int(duration / 60)
                                return "\(minutes / 60) h \(String(format: "%02d", minutes % 60)) min"
                            })
                            savedMetric("Natt-HRV", value: report.hrvMilliseconds.map { "\(Int($0.rounded())) ms" })
                            savedMetric("Vilopuls", value: report.restingHeartRateBPM.map { "\(Int($0.rounded())) bpm" })
                            savedMetric("Kroppsbatteri", value: report.bodyBatteryScore.map { "\($0) / 100" })
                            savedMetric(report.kind == .morning ? "Steg vid fångst" : "Dagens steg", value: report.steps.map { Int($0).formatted() })
                            savedMetric(report.kind == .morning ? "Aktiv energi" : "Dagens aktiva energi", value: report.activeEnergyKcal.map { "\(Int($0.rounded())) kcal" })
                        }
                    }
                    Text(report.kind == .morning ? "Det här är värdena som sparades vid morgonrapporten. De uppdateras inte när nya data kommer från Apple Hälsa." : "Det här är värdena som sparades vid kvällsrapporten. Dagens aktivitet och återhämtning visas som en fryst ögonblicksbild.")
                        .font(.caption).foregroundStyle(VITALPalette.muted).padding(.horizontal, 4)
                }
                .padding(VITALSpacing.page).padding(.top, 12).padding(.bottom, 28)
            }
        }
        .navigationTitle("Sparad rapport")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reportComponent(_ title: String, score: Double?) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text(score.map { "\(Int($0.rounded())) / 100" } ?? "—")
                .font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(VITALPalette.cloud)
        }
    }

    private func savedMetric(_ title: String, value: String?) -> some View {
        HStack {
            Text(title).foregroundStyle(VITALPalette.muted)
            Spacer()
            Text(value ?? "—").font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(value == nil ? VITALPalette.amber : VITALPalette.cloud)
        }
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
    @StateObject private var waterTracker = WaterTrackerStore()
    @StateObject private var weightJournal = WeightJournal()
    @StateObject private var medicationJournal = SemaglutideJournal()
    @State private var showingDoseEntry = false
    @State private var editingDose: MedicationDose?
    @State private var showingSideEffectEntry = false
    @State private var editingEffect: MedicationEffect?
    @State private var showAllMedicationDoses = false
    @State private var showAllMedicationEffects = false
    @State private var showingDoseReminder = false
    @State private var showingWeightEntry = false
    @State private var editingWeight: WeightEntry?
    @State private var showingTargetWeightEntry = false
    @State private var showingBloodPressureEntry = false
    @State private var editingBloodPressure: BloodPressureEntry?
    @State private var showingProgressPhotos = false
    @StateObject private var progressPhotos = ProgressPhotoJournal()
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
                            VStack(alignment: .leading, spacing: 14) {
                                Label("Andning & syresättning", systemImage: "lungs.fill")
                                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                                HStack(spacing: 12) {
                                    HealthValueTile(title: "Andningsfrekvens", value: health.snapshot.respiratoryRateText, tint: VITALPalette.violet)
                                    HealthValueTile(title: "Syremättnad", value: health.snapshot.oxygenSaturationText, tint: VITALPalette.teal)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(health.snapshot.respiratoryRateDate.map { "Andning: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Andning: ingen registrerad mätning")
                                    Text(health.snapshot.oxygenSaturationDate.map { "Syremättnad: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Syremättnad: ingen registrerad mätning")
                                }
                                .font(.caption).foregroundStyle(VITALPalette.muted)
                                Text("Senaste registrerade mätning från Apple Hälsa – inte nödvändigtvis ett realtidsvärde.")
                                    .font(.caption2).foregroundStyle(VITALPalette.muted)
                            }
                        }
                        weightCard
                        waterTrackerCard
                        bloodPressureCard
                        progressPhotosCard
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
            .task { waterTracker.refreshDay() }
        }
    }

    private var weightCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Viktutveckling", systemImage: "scalemass.fill")
                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                let healthWeight = health.snapshot.latestWeight
                let current = healthWeight ?? weightJournal.latest?.kilograms
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(current.map { String(format: "%.1f", $0) } ?? "—")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(VITALPalette.cloud).monospacedDigit()
                    Text("kg").font(.subheadline).foregroundStyle(VITALPalette.muted)
                    Spacer()
                    Text(healthWeight != nil ? "Apple Hälsa" : (weightJournal.latest != nil ? "Äldre egen logg" : "Inväntar data"))
                        .font(.caption.weight(.medium)).foregroundStyle(VITALPalette.muted)
                }
                if let date = health.snapshot.latestWeightDate {
                    Text("Senaste mätning · \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                } else if healthWeight == nil {
                    Text("Vikt visas automatiskt när Apple Hälsa har en registrerad mätning.")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                }
                if weightJournal.entries.count > 1 {
                    Text("Tidigare lokala registreringar")
                        .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.muted)
                    Chart(weightJournal.chartEntries) { entry in
                        LineMark(x: .value("Datum", entry.date), y: .value("Vikt", entry.kilograms))
                            .foregroundStyle(VITALPalette.teal).interpolationMethod(.catmullRom)
                        PointMark(x: .value("Datum", entry.date), y: .value("Vikt", entry.kilograms))
                            .foregroundStyle(VITALPalette.teal)
                    }
                    .chartYAxisLabel("kg")
                    .frame(height: 140)
                }
                if !weightJournal.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Sparad äldre historik").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.muted)
                        ForEach(weightJournal.entries.prefix(5)) { entry in
                            HStack {
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(VITALPalette.muted)
                                Spacer()
                                Text(String(format: "%.1f kg", entry.kilograms))
                                    .font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(VITALPalette.cloud)
                            }
                        }
                    }
                }
                HStack {
                    Text("Målvikt").font(.caption).foregroundStyle(VITALPalette.muted)
                    Spacer()
                    Button { showingTargetWeightEntry = true } label: {
                        HStack(spacing: 4) {
                            Text(weightJournal.targetWeight.map { String(format: "%.1f kg", $0) } ?? "Ange målvikt")
                            Image(systemName: "pencil").font(.caption2)
                        }
                        .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                    }
                }
                if let current, let target = weightJournal.targetWeight {
                    let remaining = current - target
                    Text(remaining >= 0 ? String(format: "%.1f kg till målet", remaining) : String(format: "%.1f kg under målet", abs(remaining)))
                        .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                }
                if let change = weightJournal.change, let percent = weightJournal.percentageChange {
                    HStack {
                        Text("Förändring i äldre logg").font(.caption).foregroundStyle(VITALPalette.muted)
                        Spacer()
                        Text(String(format: "%+.1f kg · %+.1f %%", change, percent))
                            .font(.caption.weight(.semibold).monospacedDigit()).foregroundStyle(change <= 0 ? VITALPalette.teal : VITALPalette.amber)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTargetWeightEntry) {
            TargetWeightEntrySheet(journal: weightJournal)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var waterTrackerCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Vatten", systemImage: "drop.fill")
                        .font(.headline).foregroundStyle(VITALPalette.cloud)
                    Spacer()
                    Text("\(waterTracker.total) / \(waterTracker.goal) ml")
                        .font(.caption.weight(.semibold).monospacedDigit()).foregroundStyle(VITALPalette.teal)
                }
                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        Circle().stroke(VITALPalette.track, lineWidth: 12)
                        Circle().trim(from: 0, to: waterTracker.progress)
                            .stroke(AngularGradient(colors: [VITALPalette.teal, Color(hex: 0x58A9D6)], center: .center),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Image(systemName: "drop.fill").font(.title2).foregroundStyle(VITALPalette.teal)
                            Text("\(Int(waterTracker.progress * 100))%")
                                .font(.headline.monospacedDigit()).foregroundStyle(VITALPalette.cloud)
                        }
                    }.frame(width: 104, height: 104)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(max(0, waterTracker.goal - waterTracker.total)) ml")
                            .font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(VITALPalette.cloud)
                        Text("kvar till dagsmålet").font(.caption).foregroundStyle(VITALPalette.muted)
                        Text("Dagsmål \(waterTracker.goal) ml").font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.teal)
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 9) {
                    waterAddButton(150, label: "150 ml")
                    waterAddButton(250, label: "250 ml")
                    waterAddButton(500, label: "500 ml")
                    Button { waterTracker.undo() } label: {
                        Image(systemName: "arrow.uturn.backward").frame(width: 40, height: 42)
                    }.buttonStyle(.plain).foregroundStyle(VITALPalette.muted)
                        .background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 12))
                        .disabled(waterTracker.total == 0)
                }
                HStack {
                    Label(waterTracker.remindersEnabled ? "Påminnelser på" : "Påminnelser av",
                          systemImage: "bell.badge")
                        .font(.caption.weight(.medium)).foregroundStyle(VITALPalette.muted)
                    Spacer()
                    Toggle("Påminnelser", isOn: Binding(
                        get: { waterTracker.remindersEnabled },
                        set: { waterTracker.setReminders($0) }
                    )).labelsHidden().tint(VITALPalette.teal)
                }
                if waterTracker.remindersEnabled {
                    HStack {
                        Text("Påminn var").font(.caption).foregroundStyle(VITALPalette.muted)
                        Spacer()
                        Picker("Intervall", selection: Binding(
                            get: { waterTracker.intervalHours },
                            set: { waterTracker.setInterval($0) }
                        )) {
                            Text("1 timme").tag(1)
                            Text("2 timmar").tag(2)
                            Text("3 timmar").tag(3)
                            Text("4 timmar").tag(4)
                        }.pickerStyle(.menu).tint(VITALPalette.teal)
                    }
                }
            }
        }
    }
    private func waterAddButton(_ amount: Int, label: String) -> some View {
        Button { waterTracker.add(amount) } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus").font(.caption.weight(.bold))
                Text(label).font(.caption.weight(.semibold))
            }.frame(maxWidth: .infinity).frame(height: 42)
        }
        .buttonStyle(.plain).foregroundStyle(VITALPalette.teal)
        .background(VITALPalette.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var progressPhotosCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Framstegsbilder", systemImage: "photo.on.rectangle.angled")
                        .font(.headline).foregroundStyle(VITALPalette.cloud)
                    Spacer()
                    Text("\(progressPhotos.photos.count) bilder")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                }
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill").font(.title2).foregroundStyle(VITALPalette.teal)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Din privata bildhistorik").font(.subheadline.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                        Text("Bilderna lagras lokalt i VITAL och läggs inte automatiskt i Bilder.")
                            .font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                }
                Button { showingProgressPhotos = true } label: {
                    Label("Öppna framstegsbilder", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(VITALPalette.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).foregroundStyle(VITALPalette.teal)
            }
        }
        .sheet(isPresented: $showingProgressPhotos) {
            ProgressPhotosView(journal: progressPhotos, weightJournal: weightJournal)
        }
    }

    private var bloodPressureCard: some View {
        VITALCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Blodtryck", systemImage: "heart.text.square")
                    .font(.headline).foregroundStyle(VITALPalette.cloud)
                if let date = health.snapshot.bloodPressureDate {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(health.snapshot.bloodPressureText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(VITALPalette.cloud).monospacedDigit()
                        Text("mmHg").font(.caption).foregroundStyle(VITALPalette.muted)
                    }
                    Text("Apple Hälsa · \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(VITALPalette.muted)
                } else {
                    EmptyChartState(
                        symbol: "heart.text.square",
                        title: "Ingen blodtrycksmätning hittades",
                        detail: "Blodtryck visas automatiskt när en mätning finns i Apple Hälsa."
                    )
                }
                if !bloodPressure.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Äldre lokala registreringar")
                            .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.muted)
                        ForEach(bloodPressure.entries.prefix(5)) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(entry.systolic)/\(entry.diastolic) mmHg")
                                        .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2).foregroundStyle(VITALPalette.muted)
                                }
                                Spacer()
                                if let pulse = entry.pulse {
                                    Text("\(pulse) bpm").font(.caption).foregroundStyle(VITALPalette.muted)
                                }
                            }
                        }
                        ShareLink(item: bloodPressure.doctorSummary) {
                            Label("Dela äldre sammanställning", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(VITALPalette.teal.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
                        }.foregroundStyle(VITALPalette.teal)
                    }
                }
                Text("Värden från Apple Hälsa visas som mätdata, inte som diagnos.")
                    .font(.caption2).foregroundStyle(VITALPalette.muted)
            }
        }
    }
}

@MainActor private final class WaterTrackerStore: ObservableObject {
    @Published private(set) var total: Int = 0
    @Published private(set) var remindersEnabled = false
    @Published private(set) var intervalHours = 2
    let goal = 2000
    private var additions: [Int] = []
    private var reminderGeneration = 0
    private let dateKey = "vital.water.day"
    private let entriesKey = "vital.water.entries"
    private let reminderKey = "vital.water.reminders"
    private let intervalKey = "vital.water.interval"
    init() {
        let today = Calendar.current.startOfDay(for: .now)
        let savedDay = UserDefaults.standard.object(forKey: dateKey) as? Date
        if WaterDayPolicy.shouldReset(savedDay: savedDay, now: .now, calendar: .current) {
            UserDefaults.standard.set(today, forKey: dateKey)
            UserDefaults.standard.set([Int](), forKey: entriesKey)
        }
        additions = UserDefaults.standard.array(forKey: entriesKey) as? [Int] ?? []
        total = additions.reduce(0, +)
        remindersEnabled = UserDefaults.standard.bool(forKey: reminderKey)
        intervalHours = UserDefaults.standard.integer(forKey: intervalKey)
        if intervalHours == 0 { intervalHours = 2 }
        if remindersEnabled {
            reminderGeneration += 1
            let generation = reminderGeneration
            Task { await scheduleReminders(generation: generation) }
        }
    }
    var progress: Double { min(Double(total) / Double(goal), 1) }
    func refreshDay() {
        let today = Calendar.current.startOfDay(for: .now)
        let savedDay = UserDefaults.standard.object(forKey: dateKey) as? Date
        guard WaterDayPolicy.shouldReset(savedDay: savedDay, now: .now, calendar: .current) else { return }
        UserDefaults.standard.set(today, forKey: dateKey)
        additions = []
        total = 0
        persist()
    }
    func add(_ amount: Int) {
        guard WaterDayPolicy.isValidAmount(amount) else { return }
        refreshDay()
        additions.append(amount); persist()
    }
    func undo() {
        refreshDay()
        guard !additions.isEmpty else { return }
        additions.removeLast(); persist()
    }
    private func persist() {
        total = additions.reduce(0, +)
        UserDefaults.standard.set(additions, forKey: entriesKey)
    }
    func setInterval(_ value: Int) {
        guard (1...4).contains(value) else { return }
        intervalHours = value
        UserDefaults.standard.set(value, forKey: intervalKey)
        if remindersEnabled {
            reminderGeneration += 1
            let generation = reminderGeneration
            Task { await scheduleReminders(generation: generation) }
        }
    }
    func setReminders(_ enabled: Bool) {
        guard enabled != remindersEnabled else { return }
        reminderGeneration += 1
        let generation = reminderGeneration
        if !enabled {
            remindersEnabled = false
            UserDefaults.standard.set(false, forKey: reminderKey)
            let ids = (0..<13).map { index in "vital.water.\(index)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            return
        }
        Task {
            let center = UNUserNotificationCenter.current()
            var settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
                settings = await center.notificationSettings()
            }
            guard generation == reminderGeneration else { return }
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                remindersEnabled = false
                UserDefaults.standard.set(false, forKey: reminderKey)
                return
            }
            await scheduleReminders(generation: generation)
            guard generation == reminderGeneration else { return }
            remindersEnabled = true
            UserDefaults.standard.set(true, forKey: reminderKey)
        }
    }
    private func scheduleReminders(generation: Int) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard generation == reminderGeneration else { return }
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        let ids = (0..<13).map { index in "vital.water.\(index)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        for index in 0..<13 {
            guard generation == reminderGeneration else { return }
            let hour = 8 + index * intervalHours
            if hour >= 21 { break }
            var components = DateComponents()
            components.hour = hour; components.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Dags att dricka vatten 💧"
            content.body = "Ta en liten vattenpaus och registrera mängden i VITAL."
            content.sound = .default
            let request = UNNotificationRequest(identifier: "vital.water.\(index)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
            try? await center.add(request)
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
    init(id: UUID = UUID(), date: Date = .now, systolic: Int, diastolic: Int, pulse: Int?, note: String) {
        self.id = id; self.date = date; self.systolic = systolic
        self.diastolic = diastolic; self.pulse = pulse; self.note = note
    }
}
@MainActor private final class BloodPressureJournal: ObservableObject {
    @Published private(set) var entries: [BloodPressureEntry] = []
    private let key = "vital.bloodPressureJournal.v1"
    init() {
        if let decoded = decodeJournal([BloodPressureEntry].self, key: key) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    private func valid(systolic: Int, diastolic: Int, pulse: Int?) -> Bool {
        (60...260).contains(systolic) && (30...160).contains(diastolic) &&
        systolic > diastolic && (pulse.map { (30...220).contains($0) } ?? true)
    }
    func add(systolic: Int, diastolic: Int, pulse: Int?, note: String) {
        guard valid(systolic: systolic, diastolic: diastolic, pulse: pulse) else { return }
        entries.append(BloodPressureEntry(systolic: systolic, diastolic: diastolic, pulse: pulse, note: note))
        persist()
    }
    func update(_ entry: BloodPressureEntry, systolic: Int, diastolic: Int, pulse: Int?, note: String) {
        guard valid(systolic: systolic, diastolic: diastolic, pulse: pulse),
              let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = BloodPressureEntry(id: entry.id, date: entry.date, systolic: systolic,
                                            diastolic: diastolic, pulse: pulse, note: note)
        persist()
    }
    func delete(_ entry: BloodPressureEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }
    private func persist() {
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
    let entry: BloodPressureEntry?
    @State private var systolic: String
    @State private var diastolic: String
    @State private var pulse: String
    @State private var note: String
    init(journal: BloodPressureJournal, entry: BloodPressureEntry?) {
        self.journal = journal
        self.entry = entry
        _systolic = State(initialValue: entry.map { String($0.systolic) } ?? "")
        _diastolic = State(initialValue: entry.map { String($0.diastolic) } ?? "")
        _pulse = State(initialValue: entry?.pulse.map(String.init) ?? "")
        _note = State(initialValue: entry?.note ?? "")
    }
    private var valid: Bool {
        guard let s = Int(systolic), let d = Int(diastolic) else { return false }
        let pulseIsValid = pulse.isEmpty || (Int(pulse).map { (30...220).contains($0) } ?? false)
        return (60...260).contains(s) && (30...160).contains(d) && s > d && pulseIsValid
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
            .navigationTitle(entry == nil ? "Ny mätning" : "Redigera mätning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        guard let s = Int(systolic), let d = Int(diastolic) else { return }
                        if let entry {
                            journal.update(entry, systolic: s, diastolic: d, pulse: Int(pulse), note: note)
                        } else {
                            journal.add(systolic: s, diastolic: d, pulse: Int(pulse), note: note)
                        }
                        dismiss()
                    }.disabled(!valid)
                }
            }
        }
    }
}


private struct MedicationDose: Codable, Identifiable {
    let id: UUID
    let date: Date
    let milligrams: Double
    init(id: UUID = UUID(), date: Date = .now, milligrams: Double) {
        self.id = id; self.date = date; self.milligrams = milligrams
    }
}
private struct MedicationEffect: Codable, Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let severity: Int
    let note: String
    init(id: UUID = UUID(), date: Date = .now, title: String, severity: Int, note: String) {
        self.id = id; self.date = date; self.title = title; self.severity = severity; self.note = note
    }
}
@MainActor private final class SemaglutideJournal: ObservableObject {
    @Published private(set) var doses: [MedicationDose] = []
    @Published private(set) var effects: [MedicationEffect] = []
    @Published private(set) var reminderDate: Date?
    private let center = UNUserNotificationCenter.current()
    private var reminderGeneration = 0
    init() {
        let defaults = UserDefaults.standard
        if let value = decodeJournal([MedicationDose].self, key: "vital.medication.doses.v1") {
            doses = value.sorted { $0.date > $1.date }
        }
        if let value = decodeJournal([MedicationEffect].self, key: "vital.medication.effects.v1") {
            effects = value.sorted { $0.date > $1.date }
        }
        reminderDate = defaults.object(forKey: "vital.medication.reminder.v1") as? Date
        if let reminderDate, reminderDate <= .now {
            self.reminderDate = nil
            defaults.removeObject(forKey: "vital.medication.reminder.v1")
            center.removePendingNotificationRequests(withIdentifiers: ["vital.medication.nextDose"])
            center.removeDeliveredNotifications(withIdentifiers: ["vital.medication.nextDose"])
        }
    }
    func addDose(_ mg: Double, date: Date) {
        guard mg.isFinite, (0.01...10).contains(mg) else { return }
        doses.append(MedicationDose(date: date, milligrams: mg))
        persist(doses, key: "vital.medication.doses.v1")
    }
    func updateDose(_ entry: MedicationDose, milligrams: Double, date: Date) {
        guard milligrams.isFinite, (0.01...10).contains(milligrams),
              let index = doses.firstIndex(where: { $0.id == entry.id }) else { return }
        doses[index] = MedicationDose(id: entry.id, date: date, milligrams: milligrams)
        persist(doses, key: "vital.medication.doses.v1")
    }
    func deleteDose(_ entry: MedicationDose) {
        doses.removeAll { $0.id == entry.id }
        persist(doses, key: "vital.medication.doses.v1")
    }
    func addEffect(_ title: String, severity: Int, note: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, (1...5).contains(severity) else { return }
        effects.append(MedicationEffect(title: cleanTitle, severity: severity, note: note))
        persist(effects, key: "vital.medication.effects.v1")
    }
    func updateEffect(_ entry: MedicationEffect, title: String, severity: Int, note: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, (1...5).contains(severity),
              let index = effects.firstIndex(where: { $0.id == entry.id }) else { return }
        effects[index] = MedicationEffect(id: entry.id, date: entry.date, title: cleanTitle, severity: severity, note: note)
        persist(effects, key: "vital.medication.effects.v1")
    }
    func deleteEffect(_ entry: MedicationEffect) {
        effects.removeAll { $0.id == entry.id }
        persist(effects, key: "vital.medication.effects.v1")
    }
    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }
    func setReminder(_ date: Date) async -> Bool {
        guard date > .now else { return false }
        reminderGeneration += 1
        let generation = reminderGeneration
        let identifier = "vital.medication.nextDose"
        let settings = await center.notificationSettings()
        guard generation == reminderGeneration else { return false }
        if settings.authorizationStatus == .denied { return false }
        if settings.authorizationStatus == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted, generation == reminderGeneration else { return false }
        }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "Påminnelse från VITAL"
        content.body = "Det är dags att se över din läkemedelsplan."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            guard generation == reminderGeneration else {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                return false
            }
            reminderDate = date
            UserDefaults.standard.set(date, forKey: "vital.medication.reminder.v1")
            return true
        } catch { return false }
    }
    func clearReminder() {
        reminderGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: ["vital.medication.nextDose"])
        center.removeDeliveredNotifications(withIdentifiers: ["vital.medication.nextDose"])
        reminderDate = nil
        UserDefaults.standard.removeObject(forKey: "vital.medication.reminder.v1")
    }
}
private struct DoseEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: SemaglutideJournal
    let entry: MedicationDose?
    @State private var amount: String
    @State private var date: Date
    init(journal: SemaglutideJournal, entry: MedicationDose? = nil) {
        self.journal = journal; self.entry = entry
        _amount = State(initialValue: entry.map { String(format: "%.2g", $0.milligrams) } ?? "")
        _date = State(initialValue: entry?.date ?? .now)
    }
    private var parsed: Double? { Double(amount.replacingOccurrences(of: ",", with: ".")) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Registrerad dos") {
                    TextField("Dos i mg", text: $amount).keyboardType(.decimalPad)
                    DatePicker("Datum och tid", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section { Text("Ange exakt den dos du tagit enligt din ordination. VITAL rekommenderar inte dos eller dosändring.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle(entry == nil ? "Registrera dos" : "Redigera dos").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") { if let parsed { if let entry { journal.updateDose(entry, milligrams: parsed, date: date) } else { journal.addDose(parsed, date: date) }; dismiss() } }
                        .disabled(!(parsed.map { (0.01...10).contains($0) } ?? false))
                }
            }
        }
    }
}
private struct SideEffectEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: SemaglutideJournal
    let entry: MedicationEffect?
    @State private var title: String
    @State private var severity: Int
    @State private var note: String
    init(journal: SemaglutideJournal, entry: MedicationEffect? = nil) {
        self.journal = journal; self.entry = entry
        _title = State(initialValue: entry?.title ?? "Illamående")
        _severity = State(initialValue: entry?.severity ?? 2)
        _note = State(initialValue: entry?.note ?? "")
    }
    private let choices = ["Illamående", "Förstoppning", "Diarré", "Magont", "Huvudvärk", "Yrsel", "Trötthet", "Annat"]
    var body: some View {
        NavigationStack {
            Form {
                Section("Besvär") {
                    Picker("Typ", selection: $title) { ForEach(choices, id: \.self) { Text($0).tag($0) } }
                    Stepper("Intensitet: \(severity)/5", value: $severity, in: 1...5)
                    TextField("Anteckning (valfritt)", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(entry == nil ? "Logga biverkning" : "Redigera registrering").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") { if let entry { journal.updateEffect(entry, title: title, severity: severity, note: note) } else { journal.addEffect(title, severity: severity, note: note) }; dismiss() }
                }
            }
        }
    }
}
private struct DoseReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: SemaglutideJournal
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var status: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Nästa påminnelse") {
                    DatePicker("Datum och tid", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    Text("Välj själv en tid som följer din ordination. Påminnelsen är en kalendernotis, inte ett doseringsråd.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if journal.reminderDate != nil {
                    Section {
                        Button("Ta bort sparad påminnelse", role: .destructive) {
                            journal.clearReminder()
                            status = "Påminnelsen är borttagen."
                        }
                    }
                }
                if let status { Section { Text(status).font(.footnote) } }
            }
            .navigationTitle("Läkemedelspåminnelse").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Stäng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        Task {
                            let success = await journal.setReminder(date)
                            status = success ? "Påminnelsen är sparad." : "Kunde inte aktivera notisen. Kontrollera notisbehörigheten i iOS-inställningarna."
                        }
                    }
                }
            }
        }
    }
}

private struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let kilograms: Double
    let note: String
    init(id: UUID = UUID(), date: Date = .now, kilograms: Double, note: String) {
        self.id = id; self.date = date; self.kilograms = kilograms; self.note = note
    }
}
@MainActor private final class WeightJournal: ObservableObject {
    @Published private(set) var entries: [WeightEntry] = []
    @Published var targetWeight: Double? {
        didSet {
            if let targetWeight, targetWeight.isFinite, (25...350).contains(targetWeight) {
                UserDefaults.standard.set(targetWeight, forKey: "vital.weight.target.v1")
            } else {
                UserDefaults.standard.removeObject(forKey: "vital.weight.target.v1")
            }
        }
    }
    private let key = "vital.weight.journal.v1"
    init() {
        let savedTarget = UserDefaults.standard.object(forKey: "vital.weight.target.v1") as? Double
        targetWeight = savedTarget.flatMap { $0.isFinite && (25...350).contains($0) ? $0 : nil }
        if let decoded = decodeJournal([WeightEntry].self, key: key) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    func add(_ kilograms: Double, note: String) {
        guard kilograms.isFinite, (25...350).contains(kilograms) else { return }
        entries.append(WeightEntry(kilograms: kilograms, note: note))
        persist()
    }
    func update(_ entry: WeightEntry, kilograms: Double, note: String) {
        guard kilograms.isFinite, (25...350).contains(kilograms),
              let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = WeightEntry(id: entry.id, date: entry.date, kilograms: kilograms, note: note)
        persist()
    }
    func delete(_ entry: WeightEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }
    private func persist() {
        entries.sort { $0.date > $1.date }
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: key) }
    }
    var latest: WeightEntry? { entries.first }
    var change: Double? {
        guard let first = entries.last, let last = entries.first else { return nil }
        return last.kilograms - first.kilograms
    }
    var percentageChange: Double? {
        guard let first = entries.last, let last = entries.first, first.kilograms > 0 else { return nil }
        return ((last.kilograms - first.kilograms) / first.kilograms) * 100
    }
    var chartEntries: [WeightEntry] { Array(entries.reversed().suffix(30)) }
}
private struct WeightEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: WeightJournal
    let entry: WeightEntry?
    @State private var value: String
    @State private var note: String
    init(journal: WeightJournal, entry: WeightEntry? = nil) {
        self.journal = journal
        self.entry = entry
        _value = State(initialValue: entry.map { String(format: "%.1f", $0.kilograms) } ?? "")
        _note = State(initialValue: entry?.note ?? "")
    }
    private var parsed: Double? { Double(value.replacingOccurrences(of: ",", with: ".")) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Vikt") {
                    TextField("Vikt i kg", text: $value).keyboardType(.decimalPad)
                    TextField("Anteckning (valfritt)", text: $note)
                    if let entry {
                        LabeledContent("Mätdatum", value: entry.date.formatted(date: .long, time: .shortened))
                        Text("Mätdatumet behålls när en registrering korrigeras.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(entry == nil ? "Registrera vikt" : "Redigera vikt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        if let parsed {
                            if let entry { journal.update(entry, kilograms: parsed, note: note) }
                            else { journal.add(parsed, note: note) }
                            dismiss()
                        }
                    }.disabled(!(parsed.map { (25...350).contains($0) } ?? false))
                }
            }
        }
    }
}

private struct TargetWeightEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: WeightJournal
    @State private var value: String
    init(journal: WeightJournal) {
        self.journal = journal
        _value = State(initialValue: journal.targetWeight.map { String(format: "%.1f", $0) } ?? "")
    }
    private var parsed: Double? { Double(value.replacingOccurrences(of: ",", with: ".")) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Personligt mål") {
                    TextField("Målvikt i kg", text: $value).keyboardType(.decimalPad)
                    Text("Målvikt är helt valfri. VITAL föreslår inget standardmål.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if journal.targetWeight != nil {
                    Section {
                        Button("Ta bort målvikt", role: .destructive) {
                            journal.targetWeight = nil
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Ange målvikt").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Avbryt") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        if let parsed { journal.targetWeight = parsed; dismiss() }
                    }.disabled(!(parsed.map { (25...350).contains($0) } ?? false))
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


// MARK: - Private progress photo journal

private struct ProgressPhoto: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let date: Date
    let note: String
    init(fileName: String, date: Date, note: String) {
        id = UUID(); self.fileName = fileName; self.date = date; self.note = note
    }
}

@MainActor private final class ProgressPhotoJournal: ObservableObject {
    @Published private(set) var photos: [ProgressPhoto] = []
    private let key = "vital.progressPhotos.v1"
    private var folder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VITALProgressPhotos", isDirectory: true)
    }
    init() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var folderURL = folder
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folderURL.setResourceValues(values)
        if let saved = decodeJournal([ProgressPhoto].self, key: key) {
            photos = saved.filter { FileManager.default.fileExists(atPath: folder.appendingPathComponent($0.fileName).path) }
                .sorted { $0.date > $1.date }
        }
    }
    func imageURL(for photo: ProgressPhoto) -> URL { folder.appendingPathComponent(photo.fileName) }
    func add(_ data: Data, date: Date, note: String) throws {
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.88) else {
            throw PhotoError.invalidImage
        }
        let name = UUID().uuidString + ".jpg"
        let imageURL = folder.appendingPathComponent(name)
        try jpeg.write(to: imageURL, options: .atomic)
        do {
            var imageURLWithBackupPolicy = imageURL
            var imageValues = URLResourceValues()
            imageValues.isExcludedFromBackup = true
            try imageURLWithBackupPolicy.setResourceValues(imageValues)
        } catch {
            try? FileManager.default.removeItem(at: imageURL)
            throw PhotoError.backupExclusionFailed
        }
        photos.append(ProgressPhoto(fileName: name, date: date, note: note))
        photos.sort { $0.date > $1.date }
        persist()
    }
    func delete(_ photo: ProgressPhoto) {
        try? FileManager.default.removeItem(at: imageURL(for: photo))
        photos.removeAll { $0.id == photo.id }
        persist()
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(photos) { UserDefaults.standard.set(data, forKey: key) }
    }
    enum PhotoError: LocalizedError {
        case invalidImage
        case backupExclusionFailed
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Bilden kunde inte läsas. Välj en annan bild."
            case .backupExclusionFailed:
                return "Bilden kunde inte sparas med rätt integritetsskydd. Försök igen."
            }
        }
    }
}

private struct ProgressPhotosView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var journal: ProgressPhotoJournal
    @ObservedObject var weightJournal: WeightJournal
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var selectedIDs: Set<UUID> = []
    @State private var photoDate = Date.now
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var showingGuide = false
    @State private var showingComparison = false

    private var selectedPhotos: [ProgressPhoto] {
        journal.photos.filter { selectedIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VITALCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Privat fotohistorik", systemImage: "lock.fill")
                                    .font(.headline).foregroundStyle(VITALPalette.teal)
                                Text("Följ förändringen över tid. Bilderna sparas bara på den här enheten i VITAL.")
                                    .font(.subheadline).foregroundStyle(VITALPalette.muted)
                                DatePicker("Fotodatum", selection: $photoDate, displayedComponents: .date)
                                    .tint(VITALPalette.teal)
                                TextField("Anteckning (valfritt)", text: $note)
                                    .textFieldStyle(.roundedBorder)
                                PhotosPicker(selection: $pickerItems, maxSelectionCount: 1, matching: .images) {
                                    Label("Lägg till framstegsbild", systemImage: "plus.circle.fill")
                                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
                                        .background(VITALPalette.teal, in: RoundedRectangle(cornerRadius: 14))
                                        .foregroundStyle(VITALPalette.surface)
                                }
                                .onChange(of: pickerItems) { _, items in
                                    guard let item = items.first else { return }
                                    let selectedDate = photoDate
                                    let selectedNote = note
                                    Task {
                                        do {
                                            guard let data = try await item.loadTransferable(type: Data.self) else { return }
                                            try journal.add(data, date: selectedDate, note: selectedNote)
                                            pickerItems = []; note = ""; photoDate = .now; errorMessage = nil
                                        } catch { errorMessage = error.localizedDescription }
                                    }
                                }
                                if let errorMessage {
                                    Text(errorMessage).font(.caption).foregroundStyle(VITALPalette.amber)
                                }
                            }
                        }
                        VITALCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Jämför två bilder").font(.headline).foregroundStyle(VITALPalette.cloud)
                                    Spacer()
                                    Text("\(selectedIDs.count)/2 valda").font(.caption).foregroundStyle(VITALPalette.teal)
                                }
                                Text("Markera två bilder i historiken för att jämföra dem sida vid sida.")
                                    .font(.caption).foregroundStyle(VITALPalette.muted)
                                Button {
                                    showingComparison = true
                                } label: {
                                    Label("Jämför valda bilder", systemImage: "arrow.left.arrow.right")
                                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                                        .background(VITALPalette.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain).foregroundStyle(VITALPalette.teal)
                                .disabled(selectedIDs.count != 2)
                                .opacity(selectedIDs.count == 2 ? 1 : 0.45)
                            }
                        }
                        HStack {
                            Text("Bildhistorik").font(.title3.bold()).foregroundStyle(VITALPalette.cloud)
                            Spacer()
                            Button { showingGuide = true } label: {
                                Label("Fotoguide", systemImage: "camera.aperture").font(.caption.weight(.semibold))
                            }.foregroundStyle(VITALPalette.teal)
                        }
                        if journal.photos.isEmpty {
                            EmptyChartState(symbol: "camera", title: "Inga bilder ännu", detail: "Lägg till din första bild när du vill börja följa utvecklingen.")
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(journal.photos) { photo in
                                    ProgressPhotoTile(photo: photo, journal: journal,
                                                      selected: selectedIDs.contains(photo.id)) {
                                        if selectedIDs.contains(photo.id) { selectedIDs.remove(photo.id) }
                                        else if selectedIDs.count < 2 { selectedIDs.insert(photo.id) }
                                        else { selectedIDs = [photo.id] }
                                    } onDelete: {
                                        selectedIDs.remove(photo.id); journal.delete(photo)
                                    }
                                }
                            }
                        }
                        if let latestWeight = weightJournal.latest {
                            Text("Senast registrerade vikt: \(latestWeight.kilograms, specifier: "%.1f") kg · \(latestWeight.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(VITALPalette.muted)
                        }
                        Text("Bilderna synkroniseras inte med iCloud och ingår inte i iCloud-säkerhetskopior. De delas inte automatiskt. Om appen raderas eller enheten försvinner kan bilderna gå förlorade.")
                            .font(.caption2).foregroundStyle(VITALPalette.muted)
                    }.padding(VITALSpacing.page).padding(.bottom, 28)
                }
            }
            .navigationTitle("Framstegsbilder").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Klar") { dismiss() } } }
            .sheet(isPresented: $showingGuide) {
                NavigationStack {
                    List {
                        Label("Använd samma plats och bakgrund varje gång.", systemImage: "location")
                        Label("Håll kameran på samma höjd och avstånd.", systemImage: "camera")
                        Label("Försök använda liknande ljus och kläder.", systemImage: "sun.max")
                        Label("Ta bilder framifrån, från sidan och bakifrån om du vill.", systemImage: "person.crop.rectangle")
                        Label("Välj ett intervall som känns rimligt för dig – bilderna är till för din egen uppföljning.", systemImage: "calendar")
                    }
                    .navigationTitle("Fotoguide")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Stäng") { showingGuide = false } } }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingComparison) {
                ProgressPhotoComparison(photos: selectedPhotos, journal: journal)
            }
        }
        .tint(VITALPalette.teal)
    }
}

private struct ProgressPhotoTile: View {
    let photo: ProgressPhoto
    @ObservedObject var journal: ProgressPhotoJournal
    let selected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button(action: onSelect) {
                ZStack(alignment: .topTrailing) {
                    if let image = UIImage(contentsOfFile: journal.imageURL(for: photo).path) {
                        Image(uiImage: image).resizable().scaledToFill().frame(height: 190).frame(maxWidth: .infinity).clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12).fill(VITALPalette.surfaceRaised).frame(height: 190)
                            .overlay(Image(systemName: "photo").foregroundStyle(VITALPalette.muted))
                    }
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title2).symbolRenderingMode(.palette)
                        .foregroundStyle(selected ? VITALPalette.teal : .white, VITALPalette.surface)
                        .padding(9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? VITALPalette.teal : VITALPalette.track, lineWidth: selected ? 2 : 1))
            }.buttonStyle(.plain)
            Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
            if !photo.note.isEmpty {
                Text(photo.note).font(.caption2).foregroundStyle(VITALPalette.muted).lineLimit(2)
            }
            Button(role: .destructive, action: onDelete) {
                Label("Radera", systemImage: "trash").font(.caption)
            }.buttonStyle(.plain).foregroundStyle(VITALPalette.amber)
        }
    }
}

private struct ProgressPhotoComparison: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [ProgressPhoto]
    @ObservedObject var journal: ProgressPhotoJournal
    var body: some View {
        NavigationStack {
            ZStack {
                VITALPalette.surface.ignoresSafeArea()
                if photos.count == 2 {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            comparisonImage(photos[0])
                            comparisonImage(photos[1])
                        }
                        HStack {
                            comparisonDate(photos[0])
                            Spacer()
                            comparisonDate(photos[1])
                        }
                        let days = Calendar.current.dateComponents([.day], from: photos[0].date, to: photos[1].date).day ?? 0
                        Text("\(max(0, days)) dagar mellan bilderna")
                            .font(.headline).foregroundStyle(VITALPalette.teal)
                        Text("Jämförelsen visar bilderna sida vid sida utan automatisk retuschering eller förändring.")
                            .font(.caption).foregroundStyle(VITALPalette.muted).multilineTextAlignment(.center)
                    }.padding(VITALSpacing.page)
                }
            }
            .navigationTitle("Jämför utveckling").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Klar") { dismiss() } } }
        }
    }
    private func comparisonImage(_ photo: ProgressPhoto) -> some View {
        Group {
            if let image = UIImage(contentsOfFile: journal.imageURL(for: photo).path) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ContentUnavailableView("Bilden saknas", systemImage: "photo")
            }
        }
        .frame(maxWidth: .infinity).frame(height: 420)
        .background(VITALPalette.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    private func comparisonDate(_ photo: ProgressPhoto) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption.weight(.semibold)).foregroundStyle(VITALPalette.cloud)
        }
    }
}
