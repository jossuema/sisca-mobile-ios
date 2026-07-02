import SwiftUI

extension Color {
    /// Inicializa un color desde un entero hex 0xRRGGBB (equivalente a Color(0xFF......) de Compose).
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Paleta de la app (mismos valores que Color.kt / las pantallas de Compose).
enum AppColor {
    static let loginGradientTop = Color(hex: 0x3A6BA3)
    static let title = Color(hex: 0x980507)
    static let subtitle = Color(hex: 0x6A6464)
    static let primaryButton = Color(hex: 0x04174E)
    static let header = Color(hex: 0x042E4E)
    static let headerAlt = Color(hex: 0x042E4E)
    static let classroomCard = Color(hex: 0x092576)
    static let accessButton = Color(hex: 0x19BC19)
    static let redBar = Color(hex: 0x901919)
    static let bodyText = Color(hex: 0x554D4D)
    static let verified = Color(hex: 0x4CAF50)
}
