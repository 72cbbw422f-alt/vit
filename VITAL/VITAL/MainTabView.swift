import SwiftUI
import Charts

struct MainTabView: View {
    @EnvironmentObject private var notifications: VitalNotifications
    @State private var activeReport: VitalReportKind?
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Idag", systemImage: "square.grid.2x2.fill") }
            HistoryView().tabItem { Label("Historik", systemImage: "chart.xyaxis.line") }
            TrainingView().tabItem { Label("Träning", systemImage: "figure.run") }
            HealthView().tabItem { Label("Hälsa", systemImage: "heart.fill") }
            SettingsView().tabItem { Label("Inställningar", systemImage: "gearshape.fill") }
        }
        .tint(VitalTheme.lime)
        .preferredColorScheme(.dark)
        .onChange(of: notifications.reportToOpen) { _, value in
            if let value { activeReport = value; notifications.reportToOpen = nil }
        }
        .onAppear {
            if let value = notifications.reportToOpen { activeReport = value; notifications.reportToOpen = nil }
        }
        .sheet(item: $activeReport) { kind in ReportDetailView(kind: kind) }
    }
}

struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { content }
                    .padding(18)
            }
            .background(VitalTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .toolbarBackground(VitalTheme.background, for: .navigationBar)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: VitalStore
    @EnvironmentObject private var health: HealthStore
    @State private var activeReport: VitalReportKind?

    var body: some View {
        Screen(title: "VITAL") {
            VStack(alignment: .leading, spacing: 5) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                    .font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(VitalTheme.lime)
                Text("Din hälsa. Din återhämtning.").font(.title2.bold())
                Text("En samlad bild av kroppens signaler.").foregroundStyle(VitalTheme.secondary)
            }

            WeatherSummaryPanel()

            Panel {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "figure.mind.and.body")
                        .font(.title2).foregroundStyle(VitalTheme.lime)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dagens dagsform").font(.headline)
                        Text(health.readinessTitle).font(.title3.bold())
                        Text(health.readinessAdvice).font(.subheadline).foregroundStyle(VitalTheme.secondary)
                    }
                }
            }

            NavigationLink { MetricDetailView(metric: .hrv) } label: {
                Panel {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(VitalTheme.lime)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("HRV-status").font(.headline)
                            Text(health.hrv.map { "\(Int($0)) ms" } ?? "Inväntar mätning")
                                .font(.system(size: 27, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("Senaste registrerade värde")
                                .font(.caption).foregroundStyle(VitalTheme.secondary)
                        }
                        Spacer(minLength: 6)
                        Text(health.hrvStatus)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VitalTheme.lime)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(VitalTheme.lime.opacity(0.12), in: Capsule())
                            .frame(maxWidth: 132)
                    }
                    Divider().overlay(VitalTheme.secondary.opacity(0.25))
                    HStack(spacing: 10) {
                        hrvBaselinePill("7 DAGAR", value: health.hrvBaseline7d)
                        hrvBaselinePill("30 DAGAR", value: health.hrvBaseline30d)
                    }
                    Text("HRV jämförs med din egen historik. Det är en återhämtningssignal som ska tolkas tillsammans med sömn, vilopuls och hur du känner dig – inte som ett fristående besked.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }
            .buttonStyle(.plain)

            NavigationLink { MetricDetailView(metric: .stress) } label: {
                Panel {
                    HStack {
                        Label("Stress", systemImage: "waveform.path.ecg.rectangle").font(.headline)
                        Spacer()
                        Text(health.stressScore.map { "\($0)/100" } ?? "—").font(.title2.bold())
                            .foregroundStyle((health.stressScore ?? 0) >= 60 ? .orange : VitalTheme.lime)
                    }
                    ProgressView(value: Double(health.stressScore ?? 0), total: 100)
                        .tint((health.stressScore ?? 0) >= 60 ? .orange : VitalTheme.lime)
                    Text(health.stressStatus).font(.title3.bold())
                    Text(health.stressDataDescription + " Stress är en uppskattning av fysiologisk aktivering, inte ett direkt mått på psykisk stress.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }
            .buttonStyle(.plain)

            NavigationLink { MetricDetailView(metric: .recovery) } label: {
                Panel {
                    HStack {
                        Label("Nattlig återhämtning", systemImage: "moon.zzz.fill").font(.headline)
                        Spacer()
                        Text(health.recoveryScore.map { "\($0)/100" } ?? "—")
                            .font(.title2.bold()).foregroundStyle(VitalTheme.lime)
                    }
                    Text(health.recoveryStatus).font(.title3.bold())
                    Text("100 är neutralnivån. Sömn, HRV och vilopuls justerar poängen uppåt eller nedåt utifrån din egen historik.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                    Divider().overlay(VitalTheme.secondary.opacity(0.25))
                    Text("FAKTORER SOM PÅVERKAR POÄNGEN").font(.caption2.bold()).tracking(0.8)
                        .foregroundStyle(VitalTheme.secondary)
                    recoveryFactorRow("Sömn", value: health.sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) + " h" } ?? "Saknar data", contribution: health.recoverySleepContribution, range: -28...14, detail: "Jämförs med 7 timmar")
                    recoveryFactorRow("HRV", value: health.hrv.map { "\(Int($0)) ms" } ?? "Saknar data", contribution: health.recoveryHRVContribution, range: -18...12, detail: health.hrvBaseline30d.map { "30-dagars snitt \(Int($0)) ms" } ?? "Personlig baslinje byggs")
                    recoveryFactorRow("Vilopuls", value: health.restingHeartRate.map { "\(Int($0)) bpm" } ?? "Saknar data", contribution: health.recoveryPulseContribution, range: -12...8, detail: health.restingHeartRateBaseline30d.map { "30-dagars snitt \(Int($0)) bpm" } ?? "Personlig baslinje byggs")
                    Text(health.recoveryScoreExplanation)
                        .font(.caption2).foregroundStyle(VitalTheme.secondary)
                    Text("Poängen är ett VITAL-estimat, inte ett medicinskt mätvärde. Faktorerna visar modellens bidrag – inte kliniskt uppmätta procentsatser.")
                        .font(.caption2).foregroundStyle(VitalTheme.secondary)
                }
            }
            .buttonStyle(.plain)
            NavigationLink { MetricDetailView(metric: .bodyBattery) } label: {
                Panel {
                    HStack {
                        Label("VITAL Body Battery", systemImage: "battery.100percent").font(.headline)
                        Spacer()
                        Text(health.bodyBattery.map { "\($0)%" } ?? "—")
                            .font(.title2.bold()).foregroundStyle(VitalTheme.lime)
                    }
                    ProgressView(value: Double(health.bodyBattery ?? 0), total: 100).tint(VitalTheme.lime)
                    Text(health.bodyBatteryStatus).font(.title3.bold())
                    Text("Uppskattning av kvarvarande energi. Aktivitet belastar, medan registrerad vila med puls nära din personliga baslinje kan ge återhämtning. HRV-stress ensam tömmer inte batteriet. Inte ett medicinskt mätvärde.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }
            .buttonStyle(.plain)

            MetricTile(title: "SÖMN", value: health.sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—", unit: "timmar senaste dygnet", icon: "moon.zzz.fill")
            HStack(spacing: 12) {
                MetricTile(title: "STRESS", value: health.stressScore.map { "\($0)" } ?? "—", unit: "uppskattat · 0–100", icon: "waveform.path.ecg.rectangle")
                MetricTile(title: "HRV", value: health.hrv.map { "\(Int($0))" } ?? "—", unit: "ms · senaste värde", icon: "waveform.path.ecg")
                MetricTile(title: "STEG", value: health.steps.map { Int($0).formatted() } ?? "—", unit: "idag", icon: "figure.walk")
            }
            Panel {
                HStack {
                    Label("Vilopuls · personlig jämförelse", systemImage: "heart.text.square.fill").font(.headline)
                    Spacer()
                    Text(health.restingPulseComparison).font(.caption.weight(.bold))
                        .foregroundStyle(health.restingPulseIsElevated ? .orange : VitalTheme.lime)
                }
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(health.restingHeartRate.map { "\(Int($0))" } ?? "—")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("slag/min · senaste värde").font(.caption).foregroundStyle(VitalTheme.secondary)
                }
                HStack(spacing: 10) {
                    baselinePill("7 dagar", value: health.restingHeartRateBaseline7d)
                    baselinePill("30 dagar", value: health.restingHeartRateBaseline30d)
                }
                Text("Jämförelsen bygger på dina egna mätningar. Enstaka avvikelser behöver inte betyda något i sig.")
                    .font(.caption2).foregroundStyle(VitalTheme.secondary)
            }

            HealthMonitorPanel()

            Panel {
                HStack {
                    Label("Personliga trender", systemImage: "chart.xyaxis.line").font(.headline)
                    Spacer()
                    Text("30 DAGAR").font(.caption2.weight(.bold)).tracking(0.7).foregroundStyle(VitalTheme.secondary)
                }
                HStack(spacing: 12) {
                    DashboardMiniTrend(title: "HRV", value: health.hrv.map { "\(Int($0)) ms" } ?? "—", points: health.hrvHistory, unit: "ms")
                    DashboardMiniTrend(title: "Vilopuls", value: health.restingHeartRate.map { "\(Int($0)) bpm" } ?? "—", points: health.restingPulseHistory, unit: "bpm")
                }
                Text("Jämförs med din personliga historik.").font(.caption2).foregroundStyle(VitalTheme.secondary)
            }
            MoodCheckInPanel()

            NavigationLink { MetricDetailView(metric: .weight) } label: {
                Panel {
                    HStack {
                        Label("Vikt", systemImage: "scalemass.fill").font(.headline)
                        Spacer()
                        Text(health.bodyMass.map { $0.formatted(.number.precision(.fractionLength(1))) + " kg" } ?? "Ingen mätning")
                            .font(.title3.bold()).foregroundStyle(VitalTheme.lime)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(VitalTheme.secondary)
                    }
                    Text("Öppna viktkurva och utveckling över tid").font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }.buttonStyle(.plain)
            NavigationLink { MetricDetailView(metric: .bloodPressure) } label: {
                Panel {
                    HStack {
                        Label("Blodtryck", systemImage: "waveform.path").font(.headline)
                        Spacer()
                        Text(health.systolic != nil && health.diastolic != nil ? "\(Int(health.systolic!))/\(Int(health.diastolic!)) mmHg" : "Ingen mätning")
                            .font(.title3.bold()).foregroundStyle(VitalTheme.lime)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(VitalTheme.secondary)
                    }
                    Text("Öppna blodtryckskurvor och mätningar över tid").font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }.buttonStyle(.plain)
            Panel {
                Label("VITAL Daily Report", systemImage: "doc.text.image").font(.headline)
                Text("Din detaljerade hälsosammanfattning med personliga signaler, trender och dagens rekommendation.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                HStack(spacing: 12) {
                    reportButton(title: "Morgonrapport", subtitle: "Dagens startvärden", icon: "sunrise.fill", kind: .morning)
                    reportButton(title: "Kvällsrapport", subtitle: "Dagens summering", icon: "moon.stars.fill", kind: .evening)
                }
            }
            Text(health.lastUpdated.map { "Senast uppdaterad \($0.formatted(date: .omitted, time: .shortened))" } ?? health.statusMessage)
                .font(.caption2).foregroundStyle(VitalTheme.secondary)
        }
        .sheet(item: $activeReport) { kind in ReportDetailView(kind: kind) }
        .onAppear { health.refresh() }
    }

    private func reportButton(title: String, subtitle: String, icon: String, kind: VitalReportKind) -> some View {
        Button { activeReport = kind } label: {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon).font(.system(size: 21, weight: .semibold))
                Text(title).font(.subheadline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.82)
                Text(subtitle).font(.caption2).opacity(0.78).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.black.opacity(0.9))
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(.horizontal, 15).padding(.vertical, 14)
            .background(LinearGradient(colors: [VitalTheme.lime, Color(red: 0.66, green: 0.91, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }

    private func recoveryFactorRow(_ title: String, value: String, contribution: Double?, range: ClosedRange<Double>, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(value).font(.subheadline.weight(.semibold))
                Text(contribution.map { $0 >= 0 ? "+\(Int($0.rounded())) p" : "\(Int($0.rounded())) p" } ?? "Ej medräknad")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(contribution.map { $0 >= 0 ? VitalTheme.lime : Color.orange } ?? VitalTheme.secondary)
                    .frame(minWidth: 82, alignment: .trailing)
            }
            if let contribution {
                GeometryReader { geometry in
                    let fraction = min(max((contribution - range.lowerBound) / (range.upperBound - range.lowerBound), 0), 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(VitalTheme.background)
                        Capsule().fill(contribution >= 0 ? VitalTheme.lime : Color.orange)
                            .frame(width: geometry.size.width * fraction)
                    }
                }.frame(height: 7)
            } else {
                Capsule().fill(VitalTheme.background).frame(height: 7)
            }
            Text(detail).font(.caption2).foregroundStyle(VitalTheme.secondary)
        }
        .padding(.vertical, 3)
    }
    private func hrvBaselinePill(_ title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2.weight(.semibold)).tracking(0.6)
                .foregroundStyle(VitalTheme.secondary)
            Text(value.map { "\(Int($0)) ms" } ?? "Bygger baslinje")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VitalTheme.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private func baselinePill(_ title: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption2).foregroundStyle(VitalTheme.secondary)
            Text(value.map { "\(Int($0)) bpm" } ?? "Bygger snitt").font(.subheadline.bold())
        }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(VitalTheme.background, in: RoundedRectangle(cornerRadius: 12))
    }

}


struct HealthMonitorPanel: View {
    @EnvironmentObject private var health: HealthStore

    private struct Reading: Identifiable {
        let title: String
        let value: String?
        let unit: String
        let icon: String
        var id: String { title }
    }

    private var readings: [Reading] {
        [
            Reading(title: "Puls", value: health.heartRate.map { "\(Int($0.rounded()))" }, unit: "slag/min", icon: "heart.fill"),
            Reading(title: "Andning", value: health.respiratoryRate.map { $0.formatted(.number.precision(.fractionLength(1))) }, unit: "andetag/min", icon: "lungs.fill"),
            Reading(title: "HRV", value: health.hrv.map { "\(Int($0.rounded()))" }, unit: "ms", icon: "waveform.path.ecg"),
            Reading(title: "Energi", value: health.activeEnergy.map { "\(Int($0.rounded()))" }, unit: "kcal", icon: "flame.fill"),
            Reading(title: "Temp", value: health.wristTemperature.map { $0.formatted(.number.precision(.fractionLength(1))) }, unit: "°C", icon: "thermometer")
        ]
    }

    var body: some View {
        Panel {
            HStack {
                Label("Hälsomonitor", systemImage: "waveform.path.ecg").font(.headline)
                Spacer()
                Text("APPLE HÄLSA").font(.caption2.bold()).foregroundStyle(VitalTheme.secondary)
            }
            HStack(alignment: .top, spacing: 7) {
                ForEach(readings) { reading in
                    VStack(spacing: 8) {
                        Capsule().fill(VitalTheme.background)
                            .frame(width: 27, height: 68)
                            .overlay(alignment: .center) {
                                Circle()
                                    .fill(reading.value == nil ? VitalTheme.secondary.opacity(0.45) : VitalTheme.lime)
                                    .frame(width: 13, height: 13)
                                    .shadow(color: reading.value == nil ? .clear : VitalTheme.lime.opacity(0.35), radius: 5)
                            }
                        Text(reading.value ?? "—")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(reading.unit)
                            .font(.system(size: 9)).foregroundStyle(VitalTheme.secondary)
                            .lineLimit(2).multilineTextAlignment(.center).frame(height: 23)
                        Image(systemName: reading.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(reading.value == nil ? VitalTheme.secondary : VitalTheme.lime)
                        Text(reading.title.uppercased())
                            .font(.system(size: 8, weight: .bold)).tracking(0.3)
                            .foregroundStyle(VitalTheme.secondary).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("Markeringen visar att ett värde finns registrerat – inte en medicinsk normalzon.")
                .font(.caption2).foregroundStyle(VitalTheme.secondary)
        }
    }
}

struct DashboardMiniTrend: View {
    let title: String
    let value: String
    let points: [VitalTrendPoint]
    let unit: String

    private var recent: [VitalTrendPoint] {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        return points.filter { $0.date >= start }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).tracking(0.6)
                .foregroundStyle(VitalTheme.secondary)
            Text(value).font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.8)
            if recent.count > 1 {
                Chart {
                    ForEach(recent) { point in
                        LineMark(x: .value("Datum", point.date), y: .value(unit, point.value))
                            .interpolationMethod(.linear)
                            .foregroundStyle(VitalTheme.lime)
                            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    }
                    if let last = recent.last {
                        PointMark(x: .value("Datum", last.date), y: .value(unit, last.value))
                            .foregroundStyle(VitalTheme.lime).symbolSize(28)
                    }
                }
                .chartXAxis(.hidden).chartYAxis(.hidden)
                .chartYScale(domain: miniDomain)
                .frame(height: 48)
            } else {
                Text("Samlar mätningar").font(.caption2).foregroundStyle(VitalTheme.secondary)
                    .frame(height: 48, alignment: .center)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VitalTheme.background, in: RoundedRectangle(cornerRadius: 13))
    }

    private var miniDomain: ClosedRange<Double> {
        guard let low = recent.map(\.value).min(), let high = recent.map(\.value).max() else { return 0...1 }
        let padding = max((high - low) * 0.18, 1)
        return (low - padding)...(high + padding)
    }
}

struct WeatherSummaryPanel: View {
    @State private var temperature: Double?
    @State private var condition = "Hämtar väder…"
    @State private var symbol = "cloud.sun.fill"
    @State private var updatedAt: Date?

    var body: some View {
        Panel {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 30)).foregroundStyle(Color.cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dagens väder · Hudiksvall").font(.headline)
                    Text(condition).font(.subheadline).foregroundStyle(VitalTheme.secondary)
                    if let updatedAt { Text("Uppdaterat \(updatedAt.formatted(date: .omitted, time: .shortened))").font(.caption2).foregroundStyle(VitalTheme.secondary) }
                }
                Spacer()
                Text(temperature.map { "\(Int($0.rounded()))°" } ?? "—")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
            }
        }
        .task { await loadWeather() }
    }

    private func loadWeather() async {
        // Hudiksvall city-centre coordinates; no device location permission is requested.
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=61.7274&longitude=17.1058&current=temperature_2m,weather_code&timezone=Europe%2FStockholm") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoCurrentResponse.self, from: data)
            temperature = response.current.temperature
            condition = Self.description(for: response.current.weatherCode)
            symbol = Self.symbol(for: response.current.weatherCode)
            updatedAt = Date()
        } catch {
            condition = "Väderdata kunde inte hämtas"
            symbol = "cloud.slash"
        }
    }

    private static func description(for code: Int) -> String {
        switch code {
        case 0: return "Klart"
        case 1: return "Mestadels klart"
        case 2: return "Delvis molnigt"
        case 3: return "Mulet"
        case 45, 48: return "Dimma"
        case 51, 53, 55, 56, 57: return "Duggregn"
        case 61, 63, 65, 66, 67: return "Regn"
        case 71, 73, 75, 77: return "Snö"
        case 80, 81, 82: return "Regnskurar"
        case 85, 86: return "Snöbyar"
        case 95, 96, 99: return "Åska"
        default: return "Växlande väder"
        }
    }

    private static func symbol(for code: Int) -> String {
        switch code {
        case 0, 1: return "sun.max.fill"
        case 2: return "cloud.sun.fill"
        case 3, 45, 48: return "cloud.fill"
        case 51...67, 80...82: return "cloud.drizzle.fill"
        case 71...77, 85...86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }
}

private struct OpenMeteoCurrentResponse: Decodable {
    struct Current: Decodable {
        let temperature: Double
        let weatherCode: Int
        enum CodingKeys: String, CodingKey { case temperature = "temperature_2m", weatherCode = "weather_code" }
    }
    let current: Current
}

struct MoodCheckInPanel: View {
    @EnvironmentObject private var store: VitalStore
    @State private var selected: Set<String> = []
    @State private var note = ""
    @State private var showNote = false
    private let options = ["Mår bra", "Låg", "Trött", "Stressad", "Orolig", "Nedstämd", "Pigg", "Lugn", "Motiverad", "Utmattad"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

    var body: some View {
        Panel {
            HStack {
                Label("Mående", systemImage: "face.smiling").font(.headline)
                Spacer()
                if store.todayMood != nil {
                    Label("Sparat", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(VitalTheme.lime)
                }
            }
            LazyVGrid(columns: columns, spacing: 9) {
                ForEach(options, id: \.self) { option in
                    let active = selected.contains(option)
                    Button {
                        if active { selected.remove(option) } else { selected.insert(option) }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: Self.symbol(for: option))
                                .font(.system(size: 18, weight: .medium))
                                .frame(height: 21)
                            Text(option).font(.system(size: 9, weight: .medium))
                                .lineLimit(1).minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(active ? VitalTheme.lime : VitalTheme.secondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .padding(.vertical, 5)
                        .background(active ? VitalTheme.lime.opacity(0.13) : VitalTheme.background, in: RoundedRectangle(cornerRadius: 11))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(active ? VitalTheme.lime.opacity(0.75) : VitalTheme.secondary.opacity(0.12), lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            HStack(spacing: 10) {
                Button { showNote.toggle() } label: {
                    Label(showNote ? "Dölj anteckning" : "Lägg till anteckning", systemImage: "square.and.pencil")
                        .font(.caption.weight(.medium)).foregroundStyle(VitalTheme.secondary)
                }.buttonStyle(.plain)
                Spacer()
                Button {
                    store.saveMood(moods: Array(selected).sorted(), note: note)
                } label: {
                    Label("Spara", systemImage: "checkmark")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .background(VitalTheme.lime, in: Capsule())
                        .foregroundStyle(VitalTheme.background)
                }.buttonStyle(.plain).disabled(selected.isEmpty).opacity(selected.isEmpty ? 0.45 : 1)
            }
            if showNote {
                TextField("Något du vill lägga till?", text: $note, axis: .vertical)
                    .font(.caption).padding(9)
                    .background(VitalTheme.background, in: RoundedRectangle(cornerRadius: 9))
            }
            if let today = store.todayMood {
                Text("Idag: \(today.moods.joined(separator: " · "))")
                    .font(.caption2).foregroundStyle(VitalTheme.secondary).lineLimit(1)
            }
        }
        .onAppear {
            if let today = store.todayMood {
                selected = Set(today.moods); note = today.note
                showNote = !today.note.isEmpty
            }
        }
    }

    private static func symbol(for mood: String) -> String {
        switch mood {
        case "Mår bra": return "face.smiling.fill"
        case "Låg": return "cloud.fill"
        case "Trött": return "battery.25percent"
        case "Stressad": return "bolt.fill"
        case "Orolig": return "wind"
        case "Nedstämd": return "cloud.rain.fill"
        case "Pigg": return "sun.max.fill"
        case "Lugn": return "leaf.fill"
        case "Motiverad": return "flame.fill"
        case "Utmattad": return "battery.0percent"
        default: return "circle"
        }
    }
}

enum VitalMetric: String, Identifiable {
    case hrv, restingPulse, recovery, bodyBattery, stress, weight, bloodPressure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hrv: return "HRV"
        case .restingPulse: return "Vilopuls"
        case .recovery: return "Nattlig återhämtning"
        case .bodyBattery: return "Body Battery"
        case .stress: return "Stress"
        case .weight: return "Vikt"
        case .bloodPressure: return "Blodtryck"
        }
    }
    var symbol: String {
        switch self {
        case .hrv: return "waveform.path.ecg"
        case .restingPulse: return "heart.fill"
        case .recovery: return "moon.zzz.fill"
        case .bodyBattery: return "battery.100percent"
        case .stress: return "waveform.path.ecg.rectangle"
        case .weight: return "scalemass.fill"
        case .bloodPressure: return "waveform.path"
        }
    }
}

struct MetricDetailView: View {
    let metric: VitalMetric
    @EnvironmentObject private var health: HealthStore
    var body: some View {
        Screen(title: metric.title) {
            Panel {
                Label(metric.title, systemImage: metric.symbol).font(.headline)
                switch metric {
                case .hrv:
                    currentValue(health.hrv, unit: "ms", decimals: 0)
                    HStack { baseline("7 dagar", health.hrvBaseline7d, "ms"); baseline("30 dagar", health.hrvBaseline30d, "ms") }
                    trendChart(health.hrvHistory, name: "HRV", unit: "ms")
                    Text(health.hrvBaselineDescription).font(.caption).foregroundStyle(VitalTheme.secondary)
                case .restingPulse:
                    currentValue(health.restingHeartRate, unit: "bpm", decimals: 0)
                    HStack { baseline("7 dagar", health.restingHeartRateBaseline7d, "bpm"); baseline("30 dagar", health.restingHeartRateBaseline30d, "bpm") }
                    trendChart(health.restingPulseHistory, name: "Vilopuls", unit: "bpm")
                    Text(health.restingPulseComparison).font(.caption).foregroundStyle(VitalTheme.secondary)
                case .weight:
                    currentValue(health.bodyMass, unit: "kg", decimals: 1)
                    VitalTrendChart(points: health.weightHistory, title: "Vikt", unit: "kg", months: 12, decimals: 1)
                    Text("Viktmätningar hämtas från Apple Hälsa. Endast registrerade mätningar visas.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                case .bloodPressure:
                    if let sys = health.systolic, let dia = health.diastolic {
                        Text("\(Int(sys))/\(Int(dia))").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VitalTheme.lime)
                        Text("mmHg · senaste tillgängliga värden").font(.caption).foregroundStyle(VitalTheme.secondary)
                    } else { Text("Ingen blodtrycksmätning tillgänglig").foregroundStyle(VitalTheme.secondary) }
                    BloodPressureHistoryChart(points: health.bloodPressureHistory)
                    Text("Varje punkt är en komplett blodtrycksmätning från samma tillfälle. Välj en punkt eller granska hela listan nedan.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                case .recovery:
                    Text(health.recoveryScore.map { "\($0)/100" } ?? "—").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VitalTheme.lime)
                    Text(health.recoveryStatus).font(.title3.bold())
                    Text("Utgår från 100 poäng och justeras med sömn, HRV och vilopuls. VITAL-estimat, inte ett medicinskt mätvärde.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                case .bodyBattery:
                    Text(health.bodyBattery.map { "\($0)%" } ?? "—").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VitalTheme.lime)
                    ProgressView(value: Double(health.bodyBattery ?? 0), total: 100).tint(VitalTheme.lime)
                    Text(health.bodyBatteryStatus).font(.title3.bold())
                    Text("VITALs uppskattning av dagens kvarvarande energi. Inte ett medicinskt mätvärde.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                case .stress:
                    Text(health.stressScore.map { "\($0)/100" } ?? "—").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VitalTheme.lime)
                    ProgressView(value: Double(health.stressScore ?? 0), total: 100).tint((health.stressScore ?? 0) >= 60 ? .orange : VitalTheme.lime)
                    Text(health.stressStatus).font(.title3.bold())
                    Text(health.stressDataDescription).font(.caption).foregroundStyle(VitalTheme.secondary)
                    Text("Stresspoängen bygger på flera pulsmätningar under de senaste två timmarna, jämförda med din 60-dagars vilopulsbaslinje. HRV mot din 30-dagarsbaslinje används som en kompletterande signal. Apple Hälsa ger inte ett direkt stressvärde.")
                    Text("Återhämtningskredit ges bara när det finns flera pulsmätningar över minst 45 minuter och pulsen ligger nära din personliga vilonivå.")
                        .font(.caption).foregroundStyle(VitalTheme.secondary)
                }
            }
            Panel {
                Label("Datakälla: Apple Hälsa", systemImage: "heart.text.square.fill").font(.headline)
                Text("Historiken beror på vilka mätningar som finns sparade och vilka behörigheter VITAL har fått. Saknade värden visas inte som noll.")
                    .font(.caption).foregroundStyle(VitalTheme.secondary)
                Button { health.refresh() } label: { Label("Uppdatera mätvärden", systemImage: "arrow.clockwise").frame(maxWidth: .infinity) }
                    .buttonStyle(VitalButtonStyle())
            }
        }
        .onAppear { health.refresh() }
    }

    @ViewBuilder private func currentValue(_ value: Double?, unit: String, decimals: Int) -> some View {
        Text(value.map { $0.formatted(.number.precision(.fractionLength(decimals))) + " " + unit } ?? "Inväntar mätning")
            .font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(VitalTheme.lime)
    }

    private func baseline(_ title: String, _ value: Double?, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(VitalTheme.secondary)
            Text(value.map { "\(Int($0)) \(unit)" } ?? "Bygger baslinje").font(.headline)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
            .background(VitalTheme.background, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private func trendChart(_ points: [VitalTrendPoint], name: String, unit: String) -> some View {
        VitalTrendChart(points: points, title: name, unit: unit, months: 12)
    }
}


private enum VitalHistoryPeriod: Int, CaseIterable, Identifiable {
    case one = 1, three = 3, six = 6, twelve = 12
    var id: Int { rawValue }
    var title: String { "\(rawValue) mån" }
}

struct VitalTrendChart: View {
    let points: [VitalTrendPoint]
    let title: String
    let unit: String
    let months: Int
    var decimals: Int = 0
    var compact: Bool = false
    @State private var period: VitalHistoryPeriod = .twelve
    @State private var selectedDate: Date?

    private var visiblePoints: [VitalTrendPoint] {
        let start = Calendar.current.date(byAdding: .month, value: -period.rawValue, to: Date()) ?? .distantPast
        return points.filter { $0.date >= start }
    }
    private var selectedPoint: VitalTrendPoint? {
        guard let selectedDate else { return visiblePoints.last }
        return visiblePoints.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    private var chartColor: Color { VitalTheme.lime }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !compact {
                Picker("Period", selection: $period) {
                    ForEach(VitalHistoryPeriod.allCases) { p in Text(p.title).tag(p) }
                }
                .pickerStyle(.segmented)
            }
            if visiblePoints.isEmpty {
                Text("Ingen mätning under vald period.").font(.caption).foregroundStyle(VitalTheme.secondary)
                    .frame(maxWidth: .infinity, minHeight: compact ? 70 : 120)
            } else {
                if let point = selectedPoint {
                    HStack(alignment: .firstTextBaseline) {
                        Text(point.value.formatted(.number.precision(.fractionLength(decimals))) + " " + unit)
                            .font(.title3.bold()).foregroundStyle(chartColor)
                        Spacer()
                        Text(point.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(VitalTheme.secondary)
                    }
                }
                Chart {
                    ForEach(visiblePoints) { point in
                        LineMark(x: .value("Datum", point.date), y: .value(title, point.value))
                            .interpolationMethod(.linear)
                            .foregroundStyle(chartColor)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                    if let point = selectedPoint {
                        RuleMark(x: .value("Valt datum", point.date))
                            .foregroundStyle(VitalTheme.secondary.opacity(0.65))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        PointMark(x: .value("Datum", point.date), y: .value(title, point.value))
                            .foregroundStyle(chartColor)
                            .symbolSize(65)
                    }
                }
                .chartXScale(domain: chartDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: compact ? 3 : 4)) { value in
                        AxisGridLine().foregroundStyle(VitalTheme.secondary.opacity(0.12))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(VitalTheme.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(VitalTheme.secondary.opacity(0.12))
                        AxisValueLabel().foregroundStyle(VitalTheme.secondary)
                    }
                }
                .chartXSelection(value: $selectedDate)
                .frame(height: compact ? 105 : 190)
                Text("\(visiblePoints.count) mätningar · tryck eller dra i grafen för exakt värde")
                    .font(.caption2).foregroundStyle(VitalTheme.secondary)
                if !compact {
                    VStack(spacing: 0) {
                        ForEach(visiblePoints.sorted { $0.date > $1.date }) { point in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(point.date.formatted(date: .long, time: .shortened))
                                        .font(.subheadline.weight(.medium))
                                    Text(point.date.formatted(.dateTime.weekday(.wide)))
                                        .font(.caption2).foregroundStyle(VitalTheme.secondary)
                                }
                                Spacer()
                                Text(point.value.formatted(.number.precision(.fractionLength(decimals))) + " " + unit)
                                    .font(.subheadline.bold()).foregroundStyle(chartColor)
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                            .background(selectedPoint?.id == point.id ? VitalTheme.lime.opacity(0.08) : .clear)
                            .onTapGesture { selectedDate = point.date }
                            if point.id != visiblePoints.first?.id { Divider().overlay(VitalTheme.secondary.opacity(0.15)) }
                        }
                    }
                }
            }
        }
        .onChange(of: period) { _, _ in selectedDate = nil }
    }
    private var chartDomain: ClosedRange<Date> {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -period.rawValue, to: end) ?? end.addingTimeInterval(-30*86400)
        return start...end
    }
}

struct BloodPressureHistoryChart: View {
    let points: [BloodPressureTrendPoint]
    @State private var period: VitalHistoryPeriod = .twelve
    @State private var selectedDate: Date?
    private var visiblePoints: [BloodPressureTrendPoint] {
        let start = Calendar.current.date(byAdding: .month, value: -period.rawValue, to: Date()) ?? .distantPast
        return points.filter { $0.date >= start }
    }
    private var selectedPoint: BloodPressureTrendPoint? {
        guard let selectedDate else { return visiblePoints.last }
        return visiblePoints.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Period", selection: $period) {
                ForEach(VitalHistoryPeriod.allCases) { p in Text(p.title).tag(p) }
            }.pickerStyle(.segmented)
            if let point = selectedPoint {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(Int(point.systolic.rounded()))/\(Int(point.diastolic.rounded())) mmHg")
                            .font(.title3.bold()).foregroundStyle(VitalTheme.lime)
                        Text(point.date.formatted(date: .long, time: .shortened))
                            .font(.caption).foregroundStyle(VitalTheme.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Label("Övertryck", systemImage: "circle.fill").font(.caption2).foregroundStyle(VitalTheme.lime)
                        Label("Undertryck", systemImage: "circle.fill").font(.caption2).foregroundStyle(.cyan)
                    }
                }
            }
            if visiblePoints.isEmpty {
                Text("Inga kompletta blodtrycksmätningar under vald period.")
                    .font(.caption).foregroundStyle(VitalTheme.secondary).frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart {
                    ForEach(visiblePoints) { point in
                        LineMark(x: .value("Datum", point.date), y: .value("Övertryck", point.systolic), series: .value("Serie", "Övertryck"))
                            .foregroundStyle(VitalTheme.lime).lineStyle(StrokeStyle(lineWidth: 2.5))
                        LineMark(x: .value("Datum", point.date), y: .value("Undertryck", point.diastolic), series: .value("Serie", "Undertryck"))
                            .foregroundStyle(.cyan).lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    if let point = selectedPoint {
                        RuleMark(x: .value("Valt datum", point.date)).foregroundStyle(VitalTheme.secondary.opacity(0.65))
                        PointMark(x: .value("Datum", point.date), y: .value("Övertryck", point.systolic))
                            .foregroundStyle(VitalTheme.lime).symbolSize(60)
                        PointMark(x: .value("Datum", point.date), y: .value("Undertryck", point.diastolic))
                            .foregroundStyle(.cyan).symbolSize(60)
                    }
                }
                .chartXScale(domain: chartDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine().foregroundStyle(VitalTheme.secondary.opacity(0.12))
                        AxisValueLabel(format: .dateTime.month(.abbreviated)).foregroundStyle(VitalTheme.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(VitalTheme.secondary.opacity(0.12))
                        AxisValueLabel().foregroundStyle(VitalTheme.secondary)
                    }
                }
                .chartXSelection(value: $selectedDate)
                .frame(height: 205)
                Text("\(visiblePoints.count) kompletta mätningar · tryck eller dra i grafen")
                    .font(.caption2).foregroundStyle(VitalTheme.secondary)
                VStack(spacing: 0) {
                    ForEach(visiblePoints.sorted { $0.date > $1.date }) { point in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(point.date.formatted(date: .long, time: .shortened)).font(.subheadline.weight(.medium))
                                Text(point.date.formatted(.dateTime.weekday(.wide))).font(.caption2).foregroundStyle(VitalTheme.secondary)
                            }
                            Spacer()
                            Text("\(Int(point.systolic.rounded()))/\(Int(point.diastolic.rounded()))")
                                .font(.subheadline.bold()).foregroundStyle(VitalTheme.lime)
                            Text("mmHg").font(.caption2).foregroundStyle(VitalTheme.secondary)
                        }
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                        .background(selectedPoint?.id == point.id ? VitalTheme.lime.opacity(0.08) : .clear)
                        .onTapGesture { selectedDate = point.date }
                        if point.id != visiblePoints.first?.id { Divider().overlay(VitalTheme.secondary.opacity(0.15)) }
                    }
                }
            }
        }
        .onChange(of: period) { _, _ in selectedDate = nil }
    }
    private var chartDomain: ClosedRange<Date> {
        let end = Date()
        let start = Calendar.current.date(byAdding: .month, value: -period.rawValue, to: end) ?? end.addingTimeInterval(-30*86400)
        return start...end
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: VitalStore
    @EnvironmentObject private var health: HealthStore
    @State private var selectedReport: VitalDailyReport?
    var sorted: [WeightEntry] { store.weights.sorted { $0.date < $1.date } }

    var body: some View {
        Screen(title: "Historik") {
            Panel {
                Text("Vikt från Apple Hälsa").font(.headline)
                Text(health.bodyMass.map { "Senaste vikt: \($0.formatted(.number.precision(.fractionLength(1)))) kg" } ?? "Ingen viktmätning tillgänglig")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                VitalTrendChart(points: health.weightHistory, title: "Vikt", unit: "kg", months: 12, decimals: 1)
            }
            Panel {
                Text("Blodtryck från Apple Hälsa").font(.headline)
                if let systolic = health.systolic, let diastolic = health.diastolic {
                    Text("\(Int(systolic))/\(Int(diastolic)) mmHg").font(.title2.bold()).foregroundStyle(VitalTheme.lime)
                } else {
                    Text("Ingen blodtrycksmätning tillgänglig.").foregroundStyle(VitalTheme.secondary)
                }
                BloodPressureHistoryChart(points: health.bloodPressureHistory)
                Text("Endast kompletta blodtrycksmätningar med både över- och undertryck visas.").font(.caption).foregroundStyle(VitalTheme.secondary)
            }
            Panel {
                Text("Ditt mående").font(.headline)
                if store.moodEntries.isEmpty {
                    Text("Dina dagliga måendekontroller visas här.").foregroundStyle(VitalTheme.secondary)
                } else {
                    ForEach(store.moodEntries.sorted { $0.date > $1.date }) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(VitalTheme.secondary)
                            Text(entry.moods.joined(separator: " · ")).fontWeight(.semibold)
                            if !entry.note.isEmpty { Text(entry.note).font(.caption).foregroundStyle(VitalTheme.secondary) }
                        }.padding(.vertical, 4)
                    }
                }
            }
            Panel {
                Text("Daily Report – historik").font(.headline)
                if store.reports.isEmpty {
                    Text("Sparade morgon- och kvällsrapporter visas här. Öppna en rapport och välj Spara i historiken.")
                        .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                } else {
                    ForEach(store.reports.sorted { $0.date > $1.date }) { report in
                        Button { selectedReport = report } label: {
                            HStack {
                                Image(systemName: report.kind.symbol).foregroundStyle(VitalTheme.lime)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(report.kind.title).fontWeight(.semibold)
                                    Text(report.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(VitalTheme.secondary)
                                }
                                Spacer()
                                Text(report.readiness.map { "\($0)/100" } ?? "—").foregroundStyle(VitalTheme.lime).fontWeight(.bold)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(VitalTheme.secondary)
                            }.padding(.vertical, 4).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }
            }
            Panel {
                Text("Apple Hälsa").font(.headline)
                Text("VITAL läser tillgängliga mätningar från Apple Hälsa när du har gett behörighet. Historik och trender byggs utifrån data som finns tillgänglig.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                Button { health.refresh() } label: { Label("Uppdatera hälsodata", systemImage: "arrow.clockwise").frame(maxWidth: .infinity) }
                    .buttonStyle(VitalButtonStyle())
            }
        }
        .sheet(item: $selectedReport) { report in SavedReportDetailView(report: report) }
    }
}

struct TrainingView: View {
    @EnvironmentObject private var store: VitalStore
    @State private var showingAdd = false
    var body: some View {
        Screen(title: "Träning") {
            Panel {
                Text("Din träningslogg").font(.headline)
                Text("\(store.workouts.count)").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("registrerade pass totalt").foregroundStyle(VitalTheme.secondary)
            }
            Button { showingAdd = true } label: { Label("Registrera träningspass", systemImage: "plus").frame(maxWidth: .infinity) }
                .buttonStyle(VitalButtonStyle())
            Panel {
                Text("Senaste pass").font(.headline)
                if store.workouts.isEmpty { Text("Dina träningspass visas här när du registrerat dem.").foregroundStyle(VitalTheme.secondary) }
                ForEach(store.workouts.sorted { $0.date > $1.date }) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack { Text(workout.name).bold(); Spacer(); Text("\(workout.duration) min").foregroundStyle(VitalTheme.lime) }
                        Text(workout.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(VitalTheme.secondary)
                        if !workout.notes.isEmpty { Text(workout.notes).font(.caption).foregroundStyle(VitalTheme.secondary) }
                    }.padding(.vertical, 5)
                }
            }
        }.sheet(isPresented: $showingAdd) { AddWorkoutSheet() }
    }
}

struct HealthView: View {
    @EnvironmentObject private var health: HealthStore
    var body: some View {
        Screen(title: "Hälsa") {
            Panel {
                Label("Apple Hälsa & Apple Watch", systemImage: "heart.text.square.fill").font(.headline)
                Text("VITAL kan läsa de hälsovärden som finns i Apple Hälsa och som du ger appen tillgång till.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                Button { health.requestAccess() } label: { Label("Anslut / uppdatera Apple Hälsa", systemImage: "arrow.triangle.2.circlepath").frame(maxWidth: .infinity) }
                    .buttonStyle(VitalButtonStyle())
                Text(health.statusMessage).font(.caption).foregroundStyle(VitalTheme.secondary)
            }
            HStack(spacing: 12) {
                MetricTile(title: "PULS", value: health.heartRate.map { "\(Int($0))" } ?? "—", unit: "slag/min", icon: "heart.fill")
                MetricTile(title: "HRV", value: health.hrv.map { "\(Int($0))" } ?? "—", unit: "ms", icon: "waveform.path.ecg")
            }
            HStack(spacing: 12) {
                MetricTile(title: "BLODTRYCK", value: health.systolic != nil && health.diastolic != nil ? "\(Int(health.systolic!))/\(Int(health.diastolic!))" : "—", unit: "mmHg", icon: "waveform.path")
                MetricTile(title: "SÖMN", value: health.sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—", unit: "timmar", icon: "moon.zzz.fill")
            }
            Panel {
                Text("Fler hälsovärden").font(.headline)
                detailRow("Vilopuls", health.restingHeartRate, "slag/min", 0)
                detailRow("Vilopuls · 7-dagars snitt", health.restingHeartRateBaseline7d, "slag/min", 0)
                detailRow("Vilopuls · 30-dagars snitt", health.restingHeartRateBaseline30d, "slag/min", 0)
                detailRow("Andningsfrekvens", health.respiratoryRate, "andetag/min", 1)
                detailRow("Handledstemperatur", health.wristTemperature, "°C", 2)
                detailRow("Vikt från Apple Hälsa", health.bodyMass, "kg", 1)
                detailRow("Aktiv energi idag", health.activeEnergy, "kcal", 0)
                detailRow("Träningstid idag", health.exerciseMinutes, "min", 0)
            }
            Panel {
                Text("Mätvärden från Apple Hälsa").font(.headline)
                Text("Blodtryck och vikt hämtas automatiskt. Det finns inga manuella registreringsfält i VITAL.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
            }
        }
        .onAppear { health.refresh() }
    }

    private func detailRow(_ title: String, _ value: Double?, _ unit: String, _ decimals: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(VitalTheme.secondary)
            Spacer()
            Text(value.map { "\($0.formatted(.number.precision(.fractionLength(decimals)))) \(unit)" } ?? "Ej tillgängligt")
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct ReportDetailView: View {
    let kind: VitalReportKind
    @EnvironmentObject private var store: VitalStore
    @EnvironmentObject private var health: HealthStore
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: VitalDailyReport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: kind.symbol).font(.title2).foregroundStyle(VitalTheme.lime)
                            Text(kind.title).font(.headline)
                            Spacer()
                            Text("DAGLIG ÖGONBLICKSBILD").font(.system(size: 9, weight: .bold)).tracking(0.8)
                                .foregroundStyle(VitalTheme.lime).padding(.horizontal, 9).padding(.vertical, 6)
                                .background(VitalTheme.lime.opacity(0.12), in: Capsule())
                        }
                        Text(kind == .morning ? "God morgon." : "Dagen i korthet.").font(.largeTitle.bold())
                        Text(snapshot?.date.formatted(date: .complete, time: .shortened) ?? Date.now.formatted(date: .complete, time: .shortened))
                            .font(.caption).foregroundStyle(VitalTheme.secondary)
                        Text(snapshot?.summary ?? "Hälsosammanfattning saknas.").font(.subheadline).foregroundStyle(VitalTheme.secondary)
                        Text(snapshot?.captureSource ?? "Rapportens ögonblicksbild")
                            .font(.caption).foregroundStyle(VitalTheme.secondary)
                        Text("Datainsamlad: \(snapshot?.date.formatted(date: .omitted, time: .shortened) ?? "—"). Värdena ändras inte under dagen.")
                            .font(.caption2).foregroundStyle(VitalTheme.secondary)
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [Color(red: 0.07, green: 0.15, blue: 0.25), VitalTheme.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(VitalTheme.lime.opacity(0.22), lineWidth: 1))

                    Text("DAGENS NYCKELTAL").font(.caption.bold()).tracking(1.2).foregroundStyle(VitalTheme.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ReportMetric(title: "Readiness", value: snapshot?.readiness.map { "\($0)/100" } ?? "—", detail: "Sparad återhämtning", icon: "gauge.with.dots.needle.50percent")
                        ReportMetric(title: "Body Battery", value: snapshot?.bodyBattery.map { "\($0)%" } ?? "—", detail: "Sparad uppskattning", icon: "battery.100percent")
                        ReportMetric(title: "Sömn", value: snapshot?.sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) + " h" } ?? "—", detail: "Senaste dygnet", icon: "moon.zzz.fill")
                        ReportMetric(title: "Vilopuls", value: snapshot?.restingHeartRate.map { "\(Int($0)) bpm" } ?? "—", detail: "Vid rapporttillfället", icon: "heart.fill")
                        ReportMetric(title: "HRV", value: snapshot?.hrv.map { "\(Int($0)) ms" } ?? "—", detail: "Vid rapporttillfället", icon: "waveform.path.ecg")
                        ReportMetric(title: "Steg", value: snapshot?.steps.map { Int($0).formatted() } ?? "—", detail: "Vid rapporttillfället", icon: "figure.walk")
                        ReportMetric(title: "Blodtryck", value: snapshot?.bloodPressure?.replacingOccurrences(of: " mmHg", with: "") ?? "—", detail: "mmHg · senaste värde", icon: "waveform.path")
                        ReportMetric(title: "Stress", value: snapshot?.stressScore.map { "\($0)/100" } ?? "—", detail: "Fysiologisk uppskattning", icon: "waveform.path.ecg.rectangle")
                    }
                    Panel {
                        Text("Kroppens övriga signaler").font(.headline)
                        reportRow("Andningsfrekvens", snapshot?.respiratoryRate, "andetag/min", 1)
                        reportRow("Handledstemperatur", snapshot?.wristTemperature, "°C", 2)
                        reportRow("Aktiv energi", snapshot?.activeEnergy, "kcal", 0)
                        reportRow("Träningstid", snapshot?.exerciseMinutes, "min", 0)
                        reportRow("Senaste puls", snapshot?.heartRate, "slag/min", 0)
                    }
                    Panel {
                        Label(kind == .morning ? "Dagens förutsättningar" : "Kvällens återhämtning", systemImage: "figure.mind.and.body").font(.headline)
                        Text(snapshot?.recommendation ?? "Rekommendationen saknas.").font(.body)
                        Text("Anpassa alltid aktivitet efter hur du faktiskt mår. VITALs poäng är uppskattningar och inte medicinska bedömningar.")
                            .font(.caption).foregroundStyle(VitalTheme.secondary)
                    }
                    Text("Fryst ögonblicksbild. Nya mätningar påverkar först nästa rapport.")
                        .font(.caption2).foregroundStyle(VitalTheme.secondary)
                }.padding(18)
            }
            .background(VitalTheme.background.ignoresSafeArea())
            .navigationTitle("Daily Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Stäng") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadOrCreateSnapshot)
    }

    private func loadOrCreateSnapshot() {
        snapshot = store.captureReportIfNeeded(kind, health: health, source: "Sparad när rapporten öppnades")
    }

    private func reportRow(_ title: String, _ value: Double?, _ unit: String, _ decimals: Int) -> some View {
        HStack {
            Text(title).foregroundStyle(VitalTheme.secondary)
            Spacer()
            Text(value.map { "\($0.formatted(.number.precision(.fractionLength(decimals)))) \(unit)" } ?? "Ej tillgängligt")
                .fontWeight(.semibold)
        }
    }
}

struct SavedReportDetailView: View {
    let report: VitalDailyReport
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(report.kind.title).font(.largeTitle.bold())
                    Text(report.date.formatted(date: .complete, time: .shortened)).font(.caption).foregroundStyle(VitalTheme.secondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ReportMetric(title: "Readiness", value: report.readiness.map { "\($0)/100" } ?? "—", detail: "Sparad poäng", icon: "gauge.with.dots.needle.50percent")
                        ReportMetric(title: "Body Battery", value: report.bodyBattery.map { "\($0)%" } ?? "—", detail: "Sparad uppskattning", icon: "battery.100percent")
                        ReportMetric(title: "Sömn", value: report.sleepHours.map { $0.formatted(.number.precision(.fractionLength(1))) + " h" } ?? "—", detail: "Senaste dygnet", icon: "moon.zzz.fill")
                        ReportMetric(title: "Vilopuls", value: report.restingHeartRate.map { "\(Int($0)) bpm" } ?? "—", detail: "Senaste värde", icon: "heart.fill")
                        ReportMetric(title: "HRV", value: report.hrv.map { "\(Int($0)) ms" } ?? "—", detail: "Senaste värde", icon: "waveform.path.ecg")
                        ReportMetric(title: "Steg", value: report.steps.map { Int($0).formatted() } ?? "—", detail: "Den dagen", icon: "figure.walk")
                    }
                    Panel {
                        Text("Övriga värden").font(.headline)
                        Text("Blodtryck: \(report.bloodPressure ?? "Ej tillgängligt")")
                        Text("Andningsfrekvens: \(report.respiratoryRate.map { "\($0.formatted(.number.precision(.fractionLength(1)))) andetag/min" } ?? "Ej tillgängligt")")
                        Text("Aktiv energi: \(report.activeEnergy.map { "\(Int($0)) kcal" } ?? "Ej tillgängligt")")
                    }
                    Panel { Text("Analys").font(.headline); Text(report.summary) }
                    Panel { Text("Rekommendation").font(.headline); Text(report.recommendation) }
                }.padding(18)
            }.background(VitalTheme.background.ignoresSafeArea())
                .navigationTitle("Sparad rapport")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Stäng") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

struct ReportMetric: View {
    let title: String; let value: String; let detail: String; let icon: String
    var body: some View {
        Panel {
            Image(systemName: icon).font(.title3).foregroundStyle(VitalTheme.lime)
            Text(value).font(.system(size: 27, weight: .bold, design: .rounded))
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(VitalTheme.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var notifications: VitalNotifications
    @EnvironmentObject private var health: HealthStore
    var body: some View {
        Screen(title: "Inställningar") {
            Panel {
                Label("Notiser från VITAL", systemImage: "bell.badge.fill").font(.headline)
                if !notifications.isAuthorized {
                    Text("Tillåt notiser för att få rapporter och påminnelser.").font(.subheadline).foregroundStyle(VitalTheme.secondary)
                    Button { notifications.requestAndSchedule() } label: {
                        Label("Aktivera notiser", systemImage: "bell.badge").frame(maxWidth: .infinity)
                    }.buttonStyle(VitalButtonStyle())
                } else {
                    Label("Notiser aktiverade", systemImage: "checkmark.circle.fill").foregroundStyle(VitalTheme.lime)
                    Toggle("Morgonrapport · 08:00", isOn: Binding(get: { notifications.morningEnabled }, set: notifications.setMorning))
                    Toggle("Kvällsrapport · 21:00", isOn: Binding(get: { notifications.eveningEnabled }, set: notifications.setEvening))
                    Toggle("Påminnelse om blodtryck · 18:00", isOn: Binding(get: { notifications.bpDailyEnabled }, set: notifications.setBPDaily))
                        .tint(VitalTheme.lime)
                    Divider().overlay(VitalTheme.secondary.opacity(0.25))
                    Toggle("Veckopåminnelse om vägning", isOn: Binding(get: { notifications.weightReminderEnabled }, set: notifications.setWeightReminderEnabled))
                        .tint(VitalTheme.lime)
                    if notifications.weightReminderEnabled {
                        Picker("Veckodag", selection: Binding(get: { notifications.weightReminderWeekday }, set: notifications.setWeightReminderWeekday)) {
                            Text("Söndag").tag(1)
                            Text("Måndag").tag(2)
                            Text("Tisdag").tag(3)
                            Text("Onsdag").tag(4)
                            Text("Torsdag").tag(5)
                            Text("Fredag").tag(6)
                            Text("Lördag").tag(7)
                        }
                        DatePicker("Klockslag", selection: Binding(get: { notifications.weightReminderTime }, set: notifications.setWeightReminderTime), displayedComponents: .hourAndMinute)
                    }
                    Text("Ändringar sparas direkt. Notiser från iPhone kan visas på Apple Watch när notisleverans är aktiverad där.")
                        .font(.caption2).foregroundStyle(VitalTheme.secondary)
                }
                Text(notifications.status).font(.caption).foregroundStyle(VitalTheme.secondary)
            }
            Panel {
                Label("Apple Hälsa", systemImage: "heart.fill").font(.headline)
                Text("Anslut eller uppdatera åtkomsten till hälsodata. Om värden saknas kan du kontrollera varje behörighet i appen Hälsa → profilbild → Appar → VITAL.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                Button { health.requestAccess() } label: {
                    Label(health.isRefreshing ? "Hämtar hälsodata…" : "Begär / uppdatera hälsodata", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                }.buttonStyle(VitalButtonStyle()).disabled(health.isRefreshing)
                Text(health.statusMessage).font(.caption).foregroundStyle(VitalTheme.secondary)
            }
            Panel {
                Text("Om VITAL 2.1").font(.headline)
                Text("VITAL är en personlig hälsoöversikt. Body Battery och återhämtning är uppskattningar utifrån tillgängliga data, inte medicinska bedömningar.")
                    .font(.subheadline).foregroundStyle(VitalTheme.secondary)
                Text("Version 2.1").font(.caption).foregroundStyle(VitalTheme.lime)
            }
        }
        .onAppear { notifications.checkStatus(); health.refresh() }
    }
}

struct VitalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.bold))
            .foregroundStyle(VitalTheme.background).padding(.vertical, 14).padding(.horizontal, 12)
            .background(VitalTheme.lime.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 15))
    }
}

struct AddWorkoutSheet: View {
    @EnvironmentObject private var store: VitalStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var duration = "45"
    @State private var notes = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Träningspass") {
                    TextField("Namn, t.ex. Överkropp", text: $name)
                    TextField("Längd i minuter", text: $duration).keyboardType(.numberPad)
                    TextField("Anteckningar", text: $notes, axis: .vertical)
                }
                Button("Spara träningspass") {
                    store.addWorkout(name: name.isEmpty ? "Träningspass" : name, duration: Int(duration) ?? 0, notes: notes)
                    dismiss()
                }
            }.navigationTitle("Nytt träningspass").navigationBarTitleDisplayMode(.inline).scrollContentBackground(.hidden).background(VitalTheme.background)
        }.presentationDetents([.medium, .large])
    }
}

