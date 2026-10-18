import SwiftUI
import SwiftData

/// Pago a una tarjeta o crédito desde una cuenta: baja el saldo de la cuenta y el de la deuda.
/// Con "Se repite cada mes" queda como el pago automático de la deuda y se aplica solo en cada fecha.
struct PaymentFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var debts: [Debt]
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]

    /// Pago automático que se está editando.
    let recurring: RecurringPayment?

    @State private var debt: Debt?
    @State private var account: Account?
    @State private var amountText: String
    @State private var date: Date
    @State private var includesInstallments: Bool
    @State private var repeats: Bool

    init(debt: Debt? = nil) {
        recurring = nil
        _debt = State(initialValue: debt)
        _account = State(initialValue: nil)
        _amountText = State(initialValue: "")
        _date = State(initialValue: Date())
        _includesInstallments = State(initialValue: true)
        _repeats = State(initialValue: false)
    }

    init(recurring: RecurringPayment) {
        self.recurring = recurring
        _debt = State(initialValue: recurring.debt)
        _account = State(initialValue: recurring.account)
        _amountText = State(initialValue: editText(recurring.amount))
        _date = State(initialValue: recurring.nextPayDate)
        _includesInstallments = State(initialValue: recurring.includesInstallments)
        _repeats = State(initialValue: true)
    }

    private var accounts: [Account] { allAccounts.checking }
    private var amount: Double { parseDecimal(amountText) }
    private var selectedDebt: Debt? { debt ?? debts.first }
    private var selectedAccount: Account? { account ?? accounts.first }

    /// Mensualidades a meses de la tarjeta elegida; 0 si no es tarjeta o no tiene.
    private var installmentsMonthly: Double {
        guard let selectedDebt, selectedDebt.kind == .creditCard else { return 0 }
        return selectedDebt.installmentsMonthly
    }

    private var reduction: Double {
        selectedDebt?.balanceReduction(
            forPayment: amount,
            includesInstallments: installmentsMonthly > 0 && includesInstallments
        ) ?? 0
    }

    private var canSave: Bool {
        amount > 0 && selectedDebt != nil && selectedAccount != nil
    }

    /// Al editar, el calendario solo se reinicia si cambió la fecha del próximo pago.
    private var dateChanged: Bool {
        guard let recurring else { return true }
        return !Calendar.current.isDate(date, inSameDayAs: recurring.nextPayDate)
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save, onDelete: recurring == nil ? nil : delete) {
            Section {
                if recurring == nil {
                    Picker(t.debt, selection: Binding(get: { selectedDebt }, set: { debt = $0 })) {
                        ForEach(debts) { debt in
                            Text(debt.name).tag(Optional(debt))
                        }
                    }
                } else if let selectedDebt {
                    LabeledContent(t.debt, value: selectedDebt.name)
                }
                DecimalField(title: t.amount, text: $amountText, prefix: t.currencySymbol)
                AccountPicker(accounts: accounts, selection: $account)
                if installmentsMonthly > 0 {
                    Toggle(t.includesInstallments(installmentsMonthly), isOn: $includesInstallments)
                }
                if recurring == nil {
                    Toggle(t.repeatsMonthly, isOn: $repeats)
                        .checkboxStyle()
                }
                DateField(title: dateTitle, date: $date)
            } header: {
                Label(t.recordPayment, systemImage: MovementKind.payment.systemImage)
                    .sectionTitle()
            } footer: {
                if let selectedDebt {
                    Text(footer(for: selectedDebt))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if let selectedAccount {
                    LabeledContent(t.accountBalanceAfter, value: t.money(selectedAccount.balance - amount))
                } else {
                    Label(t.needsAccount, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                if let selectedDebt {
                    LabeledContent(t.debtReduction, value: t.money(reduction))
                    LabeledContent(t.debtBalanceAfter, value: t.money(selectedDebt.totalOwed - reduction))
                }
            }
        }
    }

    private var dateTitle: String {
        guard repeats else { return t.dateLabel }
        return recurring == nil ? t.firstPayment : t.nextPayment
    }

    private func footer(for debt: Debt) -> String {
        let text = debt.kind == .creditCard ? t.cardPaymentFooter : t.loanPaymentFooter
        return repeats ? text + " " + t.recurringPaymentFooter : text
    }

    private func save() {
        guard let debt = selectedDebt, let account = selectedAccount else { return }

        if repeats {
            saveRecurring(debt: debt, account: account)
            return
        }

        let applied = reduction

        let payment = Movement(kind: .payment)
        context.insert(payment)
        payment.amount = amount
        payment.date = date
        payment.note = debt.name
        payment.account = account
        payment.debt = debt
        payment.appliedToDebt = applied
        debt.balance -= applied
        try? context.save()
    }

    /// Una deuda tiene un solo pago automático: si ya tenía uno, se reemplaza.
    private func saveRecurring(debt: Debt, account: Account) {
        let reschedule = dateChanged
        let plan: RecurringPayment
        if let existing = recurring ?? debt.autoPayment {
            plan = existing
        } else {
            plan = RecurringPayment()
            context.insert(plan)
            plan.debt = debt
        }

        plan.account = account
        plan.amount = amount
        plan.includesInstallments = includesInstallments
        if reschedule {
            plan.reschedule(start: date)
        }

        // Queda como el pago configurado de la deuda (para estimar cuándo se liquida). En préstamos
        // el día también es el del pago automático en el formulario de la deuda.
        debt.monthlyPayment = amount
        if debt.kind != .creditCard {
            debt.paymentDueDay = Calendar.current.component(.day, from: date)
        }
        try? context.save()
        RecurringDeposits.update(in: context)
    }

    private func delete() {
        guard let recurring else { return }
        context.delete(recurring)
        try? context.save()
    }
}
