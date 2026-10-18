import SwiftUI
import SwiftData

private struct PayoffItem: Identifiable {
    let debt: Debt
    let estimate: PayoffEstimate

    var id: PersistentIdentifier { debt.persistentModelID }
}

/// Cada deuda con su saldo, el pago configurado, cuánto falta para liquidarla y cuándo vencen sus
/// promociones. Solo para darse una idea.
struct PayoffView: View {
    @Environment(\.l10n) private var t
    @Query(sort: \Debt.createdAt) private var debts: [Debt]

    var body: some View {
        let items = DebtKind.allCases
            .flatMap { kind in debts.filter { $0.kind == kind } }
            .map { PayoffItem(debt: $0, estimate: $0.payoffEstimate()) }

        Group {
            if debts.isEmpty {
                ContentUnavailableView(t.noDebtsTitle, systemImage: "tray", description: Text(t.noDebtsMessage))
            } else {
                List {
                    Section {
                        LabeledContent(t.totalDebt) {
                            Text(t.money(debts.reduce(0) { $0 + $1.totalOwed }))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        LabeledContent(t.monthlyPayments, value: t.perMonth(items.reduce(0) { $0 + $1.estimate.payment }))
                        if let date = debtFreeDate(items.map(\.estimate)) {
                            LabeledContent(t.debtFreeApprox, value: t.monthYearLong(date))
                        }
                    } footer: {
                        Text(t.payoffFooter)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        ForEach(items) { item in
                            NavigationLink {
                                DebtDetailView(debt: item.debt)
                            } label: {
                                PayoffRow(debt: item.debt, estimate: item.estimate)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(t.timeToPayoff)
    }

    /// Cuando se liquida la última deuda; nil si alguna no tiene fecha estimada.
    private func debtFreeDate(_ estimates: [PayoffEstimate]) -> Date? {
        let months = estimates.compactMap(\.months)
        guard months.count == estimates.count, let last = months.max(), last > 0 else { return nil }
        return LoanMath.endDate(start: Date(), months: last)
    }
}

private struct PayoffRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    let debt: Debt
    let estimate: PayoffEstimate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: debt.kind.systemImage)
                .appFont(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32 * scale)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(debt.name)
                        .appFont(.body, weight: .medium)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(t.money(debt.totalOwed))
                            .monospacedDigit()
                        Text(t.remainingBalance)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                status
                ForEach(transfers) { plan in
                    promo(plan)
                }
                if let plan = debt.autoPayment, let account = plan.account {
                    caption(t.autoPay + ": " + t.autoPaySummary(amount: plan.amount, account: account.name, next: plan.nextPayDate))
                }
                if debt.insuranceAmount > 0 {
                    caption(t.insuranceNote(debt.insuranceAmount))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var transfers: [InstallmentPlan] {
        debt.installmentPlans.filter { $0.kind == .balanceTransfer && $0.totalAmount > 0 }
    }

    @ViewBuilder
    private var status: some View {
        switch estimate.status {
        case .paidOff:
            Text(t.paidOff)
                .appFont(.subheadline)
                .foregroundStyle(.green)
        case .months(let months):
            caption(t.paymentShort(estimate.payment))
            Text(t.payoffIn(months: months, date: LoanMath.endDate(start: Date(), months: months)))
                .appFont(.subheadline, weight: .medium)
        case .noPayment:
            warning(t.noPaymentSet)
        case .paymentTooLow:
            caption(t.paymentShort(estimate.payment))
            warning(t.paymentNotEnough)
        }
    }

    @ViewBuilder
    private func promo(_ plan: InstallmentPlan) -> some View {
        if plan.transferEstimate().isExpired {
            warning(t.promoExpired + " · " + t.date(plan.promoEndDate))
        } else {
            caption(t.promoEnds(plan.promoEndDate) + " · " + t.monthsLeftShort(plan.remainingMonths()))
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .appFont(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func warning(_ text: String) -> some View {
        Text(text)
            .appFont(.subheadline)
            .foregroundStyle(.orange)
    }
}
