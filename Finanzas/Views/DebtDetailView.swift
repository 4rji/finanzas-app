import SwiftUI

struct DebtDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt
    @State private var editing = false
    @State private var paying = false

    var body: some View {
        Group {
            switch debt.kind {
            case .creditCard:
                CreditCardDetailView(debt: debt)
            case .mortgage, .autoLoan, .studentLoan:
                LoanDetailView(debt: debt)
            }
        }
        .screenBackground()
        .navigationTitle(debt.name)
        .hideAmountsToolbar()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    paying = true
                } label: {
                    Label(t.pay, systemImage: MovementKind.payment.systemImage)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(t.edit) { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            DebtFormView(kind: debt.kind, debt: debt)
        }
        .sheet(isPresented: $paying) {
            PaymentFormView(debt: debt)
        }
    }
}

/// Pago automático de la deuda: monto, cuenta de donde sale y próxima fecha.
struct AutoPaymentLine: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    var body: some View {
        if let plan = debt.autoPayment, let account = plan.account {
            LabeledContent(t.autoPay) {
                Text(t.autoPaySummary(amount: plan.amount, account: account.name, next: plan.nextPayDate))
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
