import SwiftUI

// MARK: - Colours

enum BlazeColour {
    // Backgrounds
    static let background       = Color(hex: "#0D0D0D")
    static let surface          = Color(hex: "#1A1A1A")
    static let surfaceElevated  = Color(hex: "#242424")
    static let card             = Color(hex: "#1E1E1E")

    // Brand
    static let accent            = Color(hex: "#FF4D00")   // fire orange
    static let accentSecondary   = Color(hex: "#FF8C42")   // warm ember
    static let accentGlow        = Color(hex: "#FF4D00").opacity(0.25)

    // Text
    static let textPrimary       = Color(hex: "#F5F5F5")
    static let textSecondary     = Color(hex: "#A0A0A0")
    static let textMuted         = Color(hex: "#5C5C5C")

    // Semantic
    static let success           = Color(hex: "#34C759")
    static let warning           = Color(hex: "#FFD60A")
    static let destructive       = Color(hex: "#FF3B30")

    // Progress chart segments
    static let progressDone      = Color(hex: "#FF4D00")
    static let progressRemaining = Color(hex: "#2C2C2C")
}

// MARK: - Typography

enum BlazeFont {
    // Display — hero text
    static func display(_ size: CGFloat = 34, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    // Heading
    static func heading(_ size: CGFloat = 22, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    // Body
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    // Caption
    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    // Label (numeric, stats)
    static func label(_ size: CGFloat = 14, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing

enum BlazeSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner radius

enum BlazeRadius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 20
    static let pill: CGFloat = 100
}

// MARK: - Colour hex initialiser

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255,
                            Double((int >> 8)  & 0xFF) / 255,
                            Double(int         & 0xFF) / 255,
                            1.0)
        case 8:
            (r, g, b, a) = (Double((int >> 24) & 0xFF) / 255,
                            Double((int >> 16) & 0xFF) / 255,
                            Double((int >> 8)  & 0xFF) / 255,
                            Double(int         & 0xFF) / 255)
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
