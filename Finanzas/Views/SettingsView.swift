import SwiftUI

struct SettingsView: View {
    @Environment(\.l10n) private var t
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault

    var body: some View {
        Form {
            Picker(t.languageTitle, selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(t.settings)
    }
}
