import SwiftUI
import SwiftData

/// Alta o edición de una deuda. Los campos cambian según el tipo.
struct DebtFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let kind: DebtKind
    let debt: Debt?

    @State private var name: String
    @State private var balanceText: String
    @State private var rateText: String
    @State private var paymentText: String
    @State private var dueDay: Int

    init(kind: DebtKind, debt: Debt? = nil) {
        self.kind = kind
        self.debt = debt
        _name = State(initialValue: debt?.name ?? "")
        _balanceText = State(initialValue: editText(debt?.balance ?? 0))
        _rateText = State(initialValue: editText(debt?.interestRate ?? 0))
        _paymentText = State(initialValue: editText(debt?.monthlyPayment ?? 0))
        _dueDay = State(initialValue: debt?.paymentDueDay ?? 1)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextRow(title: t.name, text: $name, prompt: t.namePlaceholder(kind))

                    switch kind {
                    case .creditCard:
                        DecimalField(title: t.currentBalance, text: $balanceText, prefix: t.currencySymbol)
                        DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
                        Picker(t.paymentDueDay, selection: $dueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text(String(day)).tag(day)
                            }
                        }
                    case .mortgage, .studentLoan:
                        DecimalField(title: t.remainingBalance, text: $balanceText, prefix: t.currencySymbol)
                        DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
                        DecimalField(title: t.monthlyPayment, text: $paymentText, prefix: t.currencySymbol)
                    }
                } header: {
                    Text(t.kindName(kind))
                } footer: {
                    Text(kind == .creditCard ? t.cardFormFooter : t.approxNote)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(t.kindName(kind))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t.save) {
                        save()
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .macSheetSize()
    }

    private func save() {
        let target: Debt
        if let debt {
            target = debt
        } else {
            target = Debt(name: trimmedName, kind: kind)
            context.insert(target)
        }

        target.name = trimmedName
        target.balance = parseDecimal(balanceText)
        target.interestRate = parseDecimal(rateText)
        if kind == .creditCard {
            target.paymentDueDay = dueDay
        } else {
            target.monthlyPayment = parseDecimal(paymentText)
        }
        try? context.save()
    }
}
