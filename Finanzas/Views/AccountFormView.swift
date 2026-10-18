import SwiftUI
import SwiftData

/// Alta o edición de una cuenta de cheques, una inversión o una meta, con su saldo (o valor) actual.
/// Inversión o meta se elige en el mismo formulario: cada quien ahorra donde prefiera.
struct AccountFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let account: Account?

    @State private var kind: AccountKind
    @State private var name: String
    @State private var balanceText: String
    @State private var goalText: String

    init(account: Account? = nil, kind: AccountKind = .checking) {
        self.account = account
        _kind = State(initialValue: account?.kind ?? kind)
        _name = State(initialValue: account?.name ?? "")
        _balanceText = State(initialValue: editText(account?.balance ?? 0))
        _goalText = State(initialValue: editText(account?.goalAmount ?? 0))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FormSheet(canSave: !trimmedName.isEmpty, onSave: save, onDelete: account == nil ? nil : delete) {
            Section {
                if kind.isSavings {
                    Picker(t.typeTitle, selection: $kind) {
                        Text(t.investment).tag(AccountKind.investment)
                        Text(t.goal).tag(AccountKind.goal)
                    }
                    .pickerStyle(.segmented)
                }
                TextRow(title: t.name, text: $name, prompt: namePlaceholder)
                DecimalField(title: balanceTitle, text: $balanceText, prefix: t.currencySymbol)
                if kind == .goal {
                    DecimalField(title: t.goalAmount, text: $goalText, prefix: t.currencySymbol)
                }
            } header: {
                Label(t.savingsKindName(kind), systemImage: kind.systemImage)
                    .sectionTitle()
            } footer: {
                Text(account == nil ? footer : footer + " " + t.accountDeleteNote)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var namePlaceholder: String {
        switch kind {
        case .checking: return t.accountNamePlaceholder
        case .investment: return t.investmentNamePlaceholder
        case .goal: return t.goalNamePlaceholder
        }
    }

    private var balanceTitle: String {
        switch kind {
        case .checking: return t.accountBalance
        case .investment: return t.investmentValue
        case .goal: return t.savedSoFar
        }
    }

    private var footer: String {
        switch kind {
        case .checking: return t.accountFooter
        case .investment: return t.investmentFooter
        case .goal: return t.goalFooter
        }
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
        target.kind = kind
        target.goalAmount = kind == .goal ? parseDecimal(goalText) : 0
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
