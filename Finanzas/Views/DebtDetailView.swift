import SwiftUI

struct DebtDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt
    @State private var editing = false

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
                Button(t.edit) { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            DebtFormView(kind: debt.kind, debt: debt)
        }
    }
}
