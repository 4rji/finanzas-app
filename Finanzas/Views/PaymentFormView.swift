import SwiftUI
import SwiftData

/// Pago a una tarjeta o crédito desde una cuenta: baja el saldo de la cuenta y el de la deuda.
struct PaymentFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var debts: [Debt]
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var debt: Debt?
    @State private var account: Account?
    @State private var amountText = ""
    @State private var date = Date()
    @State private var includesInstallments = true

    init(debt: Debt? = nil) {
        _debt = State(initialValue: debt)
    }

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

    var body: some View {
        FormSheet(canSave: canSave, onSave: save) {
            Section {
                Picker(t.debt, selection: Binding(get: { selectedDebt }, set: { debt = $0 })) {
                    ForEach(debts) { debt in
                        Text(debt.name).tag(Optional(debt))
                    }
                }
                DecimalField(title: t.amount, text: $amountText, prefix: t.currencySymbol)
                DateField(title: t.dateLabel, date: $date)
                AccountPicker(accounts: accounts, selection: $account)
                if installmentsMonthly > 0 {
                    Toggle(t.includesInstallments(installmentsMonthly), isOn: $includesInstallments)
                }
            } header: {
                Label(t.recordPayment, systemImage: MovementKind.payment.systemImage)
                    .appFont(.headline)
            } footer: {
                if let selectedDebt {
                    Text(selectedDebt.kind == .creditCard ? t.cardPaymentFooter : t.loanPaymentFooter)
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

    private func save() {
        guard let debt = selectedDebt, let account = selectedAccount else { return }
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
}
