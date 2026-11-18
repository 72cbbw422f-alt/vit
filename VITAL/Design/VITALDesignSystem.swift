import SwiftUI

enum VITALPalette {
    static let midnight = Color(hex: 0x080F1C)
    static let surface = Color(hex: 0x0B1422)
    static let surfaceRaised = Color(hex: 0x142235)
    static let teal = Color(hex: 0xC8F36A)
    static let violet = Color(hex: 0xA9A0F5)
    static let amber = Color(hex: 0xE9BD70)
    static let cloud = Color(hex: 0xF1F4F8)
    static let muted = Color(hex: 0xAAB6C8)
    static let track = Color(hex: 0x35445A)
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
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(VITALPalette.midnight, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}