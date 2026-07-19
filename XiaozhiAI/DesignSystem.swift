import SwiftUI

// MARK: - Berry Sorbet Color Palette
extension Color {
    static let auraPrimary = Color(hex: "#8127cf")
    static let auraPrimaryContainer = Color(hex: "#9c48ea")
    static let auraPrimaryFixed = Color(hex: "#f0dbff")
    static let auraSecondary = Color(hex: "#b4136d")
    static let auraSecondaryContainer = Color(hex: "#fd56a7")
    static let auraTertiary = Color(hex: "#4648d4")
    static let auraTertiaryContainer = Color(hex: "#6063ee")
    static let auraOnSurface = Color(hex: "#1a1c1d")
    static let auraOnSurfaceVariant = Color(hex: "#4d4354")
    static let auraSurface = Color(hex: "#faf9fb")
    static let auraSurfaceLow = Color(hex: "#f4f3f5")
    static let auraSurfaceHigh = Color(hex: "#e8e8ea")
    static let auraOutlineVariant = Color(hex: "#cfc2d6")
    static let auraError = Color(hex: "#ba1a1a")
    static let auraBgStart = Color(hex: "#f0dbff")
    static let auraBgEnd = Color(hex: "#e1e0ff")
    static let auraGlassBorder = Color.white.opacity(0.5)
    static let auraGlassShadow = Color(hex: "#8127cf").opacity(0.08)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography
extension Font {
    static let auraDisplayLg = Font.system(size: 32, weight: .bold, design: .rounded)
    static let auraHeadlineMd = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let auraHeadlineSm = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let auraBodyLg = Font.system(size: 18, weight: .medium, design: .rounded)
    static let auraBodyMd = Font.system(size: 16, weight: .medium, design: .rounded)
    static let auraLabelMd = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let auraLabelSm = Font.system(size: 12, weight: .bold, design: .rounded)
}

// MARK: - Corner Radius
enum AuraRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Spacing
enum AuraSpacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let containerPadding: CGFloat = 20
    static let gutter: CGFloat = 16
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.white.opacity(0.3)
                    Rectangle().fill(.ultraThinMaterial)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AuraRadius.xl, style: .continuous))
            .shadow(color: Color.auraGlassShadow, radius: 16, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: AuraRadius.xl, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
