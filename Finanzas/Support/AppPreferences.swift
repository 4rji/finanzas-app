import SwiftUI

/// Lee el idioma, el tamaño de letra, la apariencia y si los saldos están ocultos, y los aplica a toda
/// la jerarquía de vistas.
private struct AppPreferencesModifier: ViewModifier {
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large
    @AppStorage(L10n.hidesAmountsKey) private var hidesAmounts = false
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    func body(content: Content) -> some View {
        content
            .appFont(.body)
            .controlSize(textSize == .normal ? .regular : .large)
            .environment(\.textScale, textSize.scale)
            .environment(\.l10n, L10n(language: language, hidesAmounts: hidesAmounts))
            .environment(\.locale, language.locale)
            .preferredColorScheme(appearance.colorScheme)
    }
}

extension View {
    func appPreferences() -> some View {
        modifier(AppPreferencesModifier())
    }
}
