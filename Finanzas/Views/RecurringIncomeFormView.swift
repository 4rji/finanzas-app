import SwiftUI
import SwiftData

/// Alta o edición de un ingreso recurrente, como el sueldo.
struct RecurringIncomeFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    let income: RecurringIncome?

    @State private var name: String
    @State private var amountText: String
    @State private var frequency: PayFrequency
    @State private var nextDate: Date
    @State private var account: Account?

    init(income: RecurringIncome? = nil) {
        self.income = income
        _name = State(initialValue: income?.name ?? "")
        _amountText = State(initialValue: editText(income?.amount ?? 0))
        _frequency = State(initialValue: income?.frequency ?? .weekly)
        _nextDate = State(initialValue: income?.nextPayDate ?? Date())
        _account = State(initialValue: income?.account)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var amount: Double { parseDecimal(amountText) }
    private var selectedAccount: Account? { account ?? accounts.first }

    private var canSave: Bool {
        !trimmedName.isEmpty && amount > 0 && selectedAccount != nil
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save, onDelete: income == nil ? nil : delete) {
            Section {
                TextRow(title: t.name, text: $name, prompt: t.incomeNamePlaceholder)
                DecimalField(title: t.amountPerPayment, text: $amountText, prefix: t.currencySymbol)
                Picker(t.howOften, selection: $frequency) {
                    ForEach(PayFrequency.allCases) { option in
                        Text(t.frequencyName(option)).tag(option)
                    }
                }
                DateField(title: t.nextDeposit, date: $nextDate)
                AccountPicker(accounts: accounts, selection: $account)
            } header: {
                Label(t.recurringIncomeItem, systemImage: "repeat")
                    .appFont(.headline)
            } footer: {
                Text(t.recurringIncomeFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent(t.monthlyIncome, value: t.money(amount * frequency.paymentsPerMonth))
            }
        }
    }

    private func save() {
        let target: RecurringIncome
        if let income {
            target = income
        } else {
            target = RecurringIncome(name: trimmedName)
            context.insert(target)
        }

        let scheduleChanged = income == nil
            || frequency != target.frequency
            || !Calendar.current.isDate(nextDate, inSameDayAs: target.nextPayDate)

        target.name = trimmedName
        target.amount = amount
        target.account = selectedAccount
        if scheduleChanged {
            target.reschedule(nextPayDate: nextDate, frequency: frequency)
        }
        try? context.save()
        RecurringDeposits.update(in: context)
    }

    private func delete() {
        guard let income else { return }
        context.delete(income)
        try? context.save()
    }
}
