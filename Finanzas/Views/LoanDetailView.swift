import SwiftUI

/// Detalle de hipoteca o préstamo estudiantil, con estimación aproximada de intereses.
struct LoanDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    var body: some View {
        let amortization = debt.amortization
        let rows = amortization.schedule()

        Form {
            Section(t.summary) {
                LabeledContent(t.remainingBalance) {
                    Text(t.money(debt.balance))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                LabeledContent(t.interestRateApprox, value: t.percent(debt.interestRate))
                LabeledContent(t.monthlyPayment, value: t.money(debt.monthlyPayment))
            }

            Section {
                if amortization.paymentTooLow {
                    Label(t.paymentTooLow, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                LabeledContent(t.interestThisMonth, value: t.money(amortization.interestThisMonth))
                LabeledContent(t.principalThisMonth, value: t.money(amortization.principalThisMonth))
                if let last = rows.last {
                    LabeledContent(t.timeToPayoff, value: t.duration(months: rows.count))
                    LabeledContent(t.payoffDate, value: t.date(last.date))
                    LabeledContent(
                        t.totalInterestRemaining,
                        value: t.money(rows.reduce(0) { $0 + $1.interest })
                    )
                    NavigationLink(t.amortizationTable) {
                        AmortizationTableView(rows: rows)
                    }
                }
            } header: {
                Text(t.estimateSection)
            } footer: {
                Text(t.approxNote)
            }
        }
        .formStyle(.grouped)
    }
}
