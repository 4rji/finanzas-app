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
            case .mortgage, .studentLoan:
                LoanDetailView(debt: debt)
            }
        }
        .navigationTitle(debt.name)
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
