import SwiftUI

/// Lee el idioma y el tamaño de letra guardados en Configuración y los aplica a toda la jerarquía de vistas.
private struct AppPreferencesModifier: ViewModifier {
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large

    func body(content: Content) -> some View {
        content
            .appFont(.body)
            .controlSize(textSize == .normal ? .regular : .large)
            .environment(\.textScale, textSize.scale)
            .environment(\.l10n, L10n(language: language))
            .environment(\.locale, language.locale)
    }
}

extension View {
    func appPreferences() -> some View {
        modifier(AppPreferencesModifier())
    }
}
