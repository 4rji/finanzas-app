import SwiftUI

struct SettingsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large

    var body: some View {
        Form {
            Picker(t.languageTitle, selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            Picker(t.textSizeTitle, selection: $textSize) {
                ForEach(TextSize.allCases) { size in
                    Text(t.textSizeName(size)).tag(size)
                }
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(width: 420 * scale)
        #endif
        .navigationTitle(t.settings)
    }
}
