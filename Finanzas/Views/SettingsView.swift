import SwiftUI

struct SettingsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large
    @AppStorage(HomeSection.accounts.storageKey) private var showAccounts = true
    @AppStorage(HomeSection.investments.storageKey) private var showInvestments = true
    @AppStorage(HomeSection.debts.storageKey) private var showDebts = true
    @AppStorage(HomeSection.assets.storageKey) private var showAssets = true

    var body: some View {
        Form {
            Section {
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

            Section {
                Toggle(t.accounts, isOn: $showAccounts)
                Toggle(t.investments, isOn: $showInvestments)
                Toggle(t.debts, isOn: $showDebts)
                Toggle(t.assets, isOn: $showAssets)
            } header: {
                Text(t.showOnHome)
            } footer: {
                Text(t.showOnHomeFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(width: 420 * scale)
        #endif
        .navigationTitle(t.settings)
    }
}
