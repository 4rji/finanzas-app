import SwiftUI

/// Tamaño de letra elegido en Configuración. macOS no aplica el tamaño de texto del sistema
/// a las apps, así que la app escala sus propias fuentes.
enum TextSize: String, CaseIterable, Identifiable {
    case normal
    case large
    case extraLarge

    static let storageKey = "textSize"

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .normal: return 1.0
        case .large: return 1.25
        case .extraLarge: return 1.5
        }
    }
}

/// Estilos de texto con los tamaños base de macOS (en puntos).
enum AppTextStyle {
    case title3
    case body
    case headline
    case subheadline

    var baseSize: CGFloat {
        switch self {
        case .title3: return 15
        case .body, .headline: return 13
        case .subheadline: return 11
        }
    }

    var weight: Font.Weight {
        self == .headline ? .semibold : .regular
    }
}

private struct TextScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = TextSize.large.scale
}

extension EnvironmentValues {
    var textScale: CGFloat {
        get { self[TextScaleKey.self] }
        set { self[TextScaleKey.self] = newValue }
    }
}

private struct AppFontModifier: ViewModifier {
    @Environment(\.textScale) private var scale
    let style: AppTextStyle
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content.font(.system(size: style.baseSize * scale, weight: weight ?? style.weight))
    }
}

extension View {
    /// Fuente que respeta el tamaño de letra elegido en Configuración.
    func appFont(_ style: AppTextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(AppFontModifier(style: style, weight: weight))
    }
}
