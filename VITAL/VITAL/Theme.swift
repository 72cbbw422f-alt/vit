import SwiftUI

enum VitalTheme {
    static let background = Color(red: 0.025, green: 0.045, blue: 0.090)
    static let panel = Color(red: 0.055, green: 0.085, blue: 0.145)
    static let lime = Color(red: 0.72, green: 0.96, blue: 0.28)
    static let secondary = Color.white.opacity(0.58)
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VitalTheme.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    var body: some View {
        Panel {
            HStack {
                Image(systemName: icon).foregroundStyle(VitalTheme.lime)
                Spacer()
            }
            Text(value).font(.system(size: 27, weight: .bold, design: .rounded))
            Text(unit).font(.caption).foregroundStyle(VitalTheme.secondary)
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
        }
    }
}
