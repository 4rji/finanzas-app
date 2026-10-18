import SwiftUI
import SwiftData

/// Alta o edición de una cuenta y su saldo actual.
struct AccountFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let account: Account?

    @State private var name: String
    @State private var balanceText: String

    init(account: Account? = nil) {
        self.account = account
        _name = State(initialValue: account?.name ?? "")
        _balanceText = State(initialValue: editText(account?.balance ?? 0))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FormSheet(canSave: !trimmedName.isEmpty, onSave: save, onDelete: account == nil ? nil : delete) {
            Section {
                TextRow(title: t.name, text: $name, prompt: t.accountNamePlaceholder)
                DecimalField(title: t.accountBalance, text: $balanceText, prefix: t.currencySymbol)
            } header: {
                Label(t.account, systemImage: "building.columns")
                    .appFont(.headline)
            } footer: {
                Text(account == nil ? t.accountFooter : t.accountFooter + " " + t.accountDeleteNote)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        let target: Account
        if let account {
            target = account
        } else {
            target = Account(name: trimmedName)
            context.insert(target)
        }

        target.name = trimmedName
        let balance = parseDecimal(balanceText)
        // Solo si lo cambiaron, para no mover el saldo por redondeo.
        if abs(balance - target.balance) >= 0.005 {
            target.setBalance(balance)
        }
        try? context.save()
    }

    private func delete() {
        guard let account else { return }
        context.delete(account)
        try? context.save()
    }
}
