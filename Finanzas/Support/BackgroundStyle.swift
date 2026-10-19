import SwiftUI

/// Color del fondo de todas las pantallas, elegido en Configuración. Todos son tonos suaves para que
/// las tarjetas de color resalten encima.
enum BackgroundStyle: String, CaseIterable, Identifiable {
    case mint
    case ocean
    case sand
    case lavender
    case rose
    case graphite

    static let storageKey = "backgroundStyle"

    var id: String { rawValue }

    /// Degradado de la esquina de arriba a la de abajo.
    func colors(_ scheme: ColorScheme) -> [Color] {
        let dark = scheme == .dark
        switch self {
        case .mint: return dark ? [Color(hex: 0x101613), Color(hex: 0x17211C)] : [Color(hex: 0xF6F8F5), Color(hex: 0xEEF3EF)]
        case .ocean: return dark ? [Color(hex: 0x0F141A), Color(hex: 0x152029)] : [Color(hex: 0xF5F8FB), Color(hex: 0xE9F0F7)]
        case .sand: return dark ? [Color(hex: 0x16130E), Color(hex: 0x221C13)] : [Color(hex: 0xFAF7F1), Color(hex: 0xF3ECDF)]
        case .lavender: return dark ? [Color(hex: 0x13111A), Color(hex: 0x1C1927)] : [Color(hex: 0xF8F6FB), Color(hex: 0xEFEBF7)]
        case .rose: return dark ? [Color(hex: 0x181112), Color(hex: 0x24181A)] : [Color(hex: 0xFBF6F6), Color(hex: 0xF6EBEC)]
        case .graphite: return dark ? [Color(hex: 0x111212), Color(hex: 0x1B1C1C)] : [Color(hex: 0xF7F7F7), Color(hex: 0xEDEDED)]
        }
    }

    /// Resplandor de la esquina de arriba; en Configuración es el color de la muestra.
    func glow(_ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch self {
        case .mint: return Color(hex: dark ? 0x386F56 : 0xA8CCB5)
        case .ocean: return Color(hex: dark ? 0x35628A : 0xA7C3E2)
        case .sand: return Color(hex: dark ? 0x7A6234 : 0xDDC596)
        case .lavender: return Color(hex: dark ? 0x5C4F8C : 0xC4B7E4)
        case .rose: return Color(hex: dark ? 0x84444D : 0xE6B4B9)
        case .graphite: return Color(hex: dark ? 0x5A5D5E : 0xC9CBCC)
        }
    }
}
