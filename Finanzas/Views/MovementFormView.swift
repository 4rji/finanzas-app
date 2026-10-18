import SwiftUI
import SwiftData

/// Alta o edición de un ingreso extra, o edición de un depósito recurrente ya sumado.
struct MovementFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]

    let kind: MovementKind
    let movement: Movement?

    @State private var note: String
    @State private var amountText: String
    @State private var date: Date
    @State private var account: Account?

    init(kind: MovementKind, movement: Movement? = nil) {
        self.kind = kind
        self.movement = movement
        _note = State(initialValue: movement?.note ?? "")
        _amountText = State(initialValue: editText(movement?.amount ?? 0))
        _date = State(initialValue: movement?.date ?? Date())
        _account = State(initialValue: movement?.account)
    }

    /// Cuentas de cheques, más la del movimiento si es una inversión (por ejemplo, un aporte de fuera).
    private var accounts: [Account] {
        allAccounts.filter { $0.kind == .checking || $0 == movement?.account }
    }

    private var amount: Double { parseDecimal(amountText) }
    private var selectedAccount: Account? { account ?? accounts.first }

    var body: some View {
        FormSheet(
            canSave: amount > 0 && selectedAccount != nil,
            onSave: save,
            onDelete: movement == nil ? nil : delete
        ) {
            Section {
                TextRow(
                    title: t.descriptionOptional,
                    text: $note,
                    prompt: kind == .extra ? t.extraIncomePlaceholder : t.incomeNamePlaceholder
                )
                DecimalField(title: t.amount, text: $amountText, prefix: t.currencySymbol)
                DateField(title: t.dateLabel, date: $date)
                AccountPicker(accounts: accounts, selection: $account)
            } header: {
                Label(t.movementKindName(kind), systemImage: kind.systemImage)
                    .sectionTitle()
            } footer: {
                Text(kind == .extra ? t.extraIncomeFooter : t.depositFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        let target: Movement
        if let movement {
            target = movement
        } else {
            target = Movement(kind: kind)
            context.insert(target)
        }

        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.amount = amount
        target.date = date
        target.account = selectedAccount
        try? context.save()
    }

    private func delete() {
        movement?.remove()
    }
}
