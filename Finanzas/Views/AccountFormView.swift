import SwiftUI
import SwiftData

/// Alta o edición de una cuenta de cheques o una inversión, con su saldo (o valor) actual.
struct AccountFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let account: Account?
    let kind: AccountKind

    @State private var name: String
    @State private var balanceText: String

    init(account: Account? = nil, kind: AccountKind = .checking) {
        self.account = account
        self.kind = account?.kind ?? kind
        _name = State(initialValue: account?.name ?? "")
        _balanceText = State(initialValue: editText(account?.balance ?? 0))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isInvestment: Bool { kind == .investment }

    var body: some View {
        FormSheet(canSave: !trimmedName.isEmpty, onSave: save, onDelete: account == nil ? nil : delete) {
            Section {
                TextRow(
                    title: t.name,
                    text: $name,
                    prompt: isInvestment ? t.investmentNamePlaceholder : t.accountNamePlaceholder
                )
                DecimalField(
                    title: isInvestment ? t.investmentValue : t.accountBalance,
                    text: $balanceText,
                    prefix: t.currencySymbol
                )
            } header: {
                Label(isInvestment ? t.investment : t.account, systemImage: kind.systemImage)
                    .appFont(.headline)
            } footer: {
                Text(account == nil ? footer : footer + " " + t.accountDeleteNote)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: String {
        isInvestment ? t.investmentFooter : t.accountFooter
    }

    private func save() {
        let target: Account
        if let account {
            target = account
        } else {
            target = Account(name: trimmedName, kind: kind)
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
