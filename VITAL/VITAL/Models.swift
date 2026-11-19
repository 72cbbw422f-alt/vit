import Foundation

struct WeightEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var kilograms: Double
}

struct WorkoutEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var name: String
    var duration: Int
    var notes: String
}

struct BloodPressureEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var systolic: Int
    var diastolic: Int
    var pulse: Int
}


enum VitalReportKind: String, Codable, Identifiable {
    case morning, evening
    var id: String { rawValue }
    var title: String { self == .morning ? "Morgonrapport" : "Kvällsrapport" }
    var symbol: String { self == .morning ? "sunrise.fill" : "moon.stars.fill" }
}

struct VitalDailyReport: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var kind: VitalReportKind
    var readiness: Int?
    var bodyBattery: Int?
    var sleepHours: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var steps: Double?
    var respiratoryRate: Double?
    var activeEnergy: Double?
    var bloodPressure: String?
    var summary: String
    var recommendation: String
    var stressScore: Int? = nil
    var heartRate: Double? = nil
    var wristTemperature: Double? = nil
    var exerciseMinutes: Double? = nil
    var captureSource: String? = nil
}


struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var moods: [String]
    var note: String
}


struct VitalTrendPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}


struct BloodPressureTrendPoint: Identifiable {
    let date: Date
    let systolic: Double
    let diastolic: Double
    var id: Date { date }
}
