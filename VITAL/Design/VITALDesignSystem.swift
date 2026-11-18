import SwiftUI

enum VITALPalette {
    static let midnight = Color(hex: 0x080F1C)
    static let surface = Color(hex: 0x0B1422)
    static let surfaceRaised = Color(hex: 0x142235)
    static let teal = Color(hex: 0xC8F36A)
    static let violet = Color(hex: 0xA99CF8)
    static let amber = Color(hex: 0xE9BD70)
    static let cloud = Color(hex: 0xF3F6F2)
    static let muted = Color(hex: 0x9AAABD)
    static let track = Color(hex: 0x2B3D51)
    static let green = Color(hex: 0xA8E85C)
}
enum VITALSpacing {
    static let page: CGFloat = 18
    static let card: CGFloat = 18
}
struct VITALCard<Content: View>: View {
    var padding: CGFloat = VITALSpacing.card
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(
                        colors: [VITALPalette.surfaceRaised, VITALPalette.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), Color.white.opacity(0.025)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.16), radius: 15, y: 7)
    }
}
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}