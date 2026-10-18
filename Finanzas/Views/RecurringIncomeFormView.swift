import SwiftUI
import SwiftData

/// Alta o edición de un ingreso recurrente, como el sueldo.
struct RecurringIncomeFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]

    let income: RecurringIncome?

    @State private var name: String
    @State private var amountText: String
    @State private var frequency: PayFrequency
    @State private var startDate: Date
    @State private var account: Account?

    init(income: RecurringIncome? = nil) {
        self.income = income
        _name = State(initialValue: income?.name ?? "")
        _amountText = State(initialValue: editText(income?.amount ?? 0))
        _frequency = State(initialValue: income?.frequency ?? .weekly)
        _startDate = State(initialValue: income?.startDate ?? Date())
        _account = State(initialValue: income?.account)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Los aportes a inversiones se capturan en Mover dinero.
    private var accounts: [Account] { allAccounts.checking }

    private var amount: Double { parseDecimal(amountText) }
    private var selectedAccount: Account? { account ?? accounts.first }

    private var canSave: Bool {
        !trimmedName.isEmpty && amount > 0 && selectedAccount != nil
    }

    private var scheduleChanged: Bool {
        guard let income else { return true }
        return frequency != income.frequency
            || !Calendar.current.isDate(startDate, inSameDayAs: income.startDate)
    }

    /// Próximo pago calculado con la fecha de inicio y la frecuencia elegidas.
    private var nextPayDate: Date {
        if let income, !scheduleChanged { return income.nextPayDate }
        let n = frequency.firstPayIndex(onOrAfter: Date(), from: startDate)
        return frequency.payDate(n, from: startDate)
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
                DateField(title: t.startDate, date: $startDate)
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
                LabeledContent(t.nextDeposit, value: t.date(nextPayDate))
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

        let reschedule = scheduleChanged

        target.name = trimmedName
        target.amount = amount
        target.account = selectedAccount
        if reschedule {
            target.reschedule(start: startDate, frequency: frequency)
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
