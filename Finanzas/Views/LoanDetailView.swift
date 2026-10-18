import SwiftUI

/// Detalle de hipoteca o préstamo de auto o estudiantil, con estimación aproximada de intereses.
struct LoanDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    var body: some View {
        let amortization = debt.amortization
        let rows = amortization.schedule()

        ThemedForm {
            Section {
                LabeledContent(t.remainingBalance) {
                    Text(t.money(debt.balance))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                LabeledContent(t.interestRateApprox, value: t.percent(debt.interestRate))
                LabeledContent(t.monthlyPayment, value: t.money(debt.monthlyPayment))
                LabeledContent(t.monthlyInterestApprox) {
                    Text(t.money(amortization.interestThisMonth))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                AutoPaymentLine(debt: debt)
            } header: {
                Text(t.summary)
                    .sectionTitle()
            } footer: {
                Text(t.monthlyInterestFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if debt.insuranceAmount > 0 {
                Section {
                    LabeledContent(t.insuranceAmount, value: t.money(debt.insuranceAmount))
                } header: {
                    Label(t.insurance, systemImage: "shield")
                        .sectionTitle()
                } footer: {
                    Text(t.insuranceFooter)
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if amortization.paymentTooLow {
                    Label(t.paymentTooLow, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
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
                    .sectionTitle()
            } footer: {
                Text(t.approxNote)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
