import SwiftUI

struct CreditCardDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    @State private var addingPlan = false
    @State private var editingPlan: InstallmentPlan?

    var body: some View {
        let plans = debt.installmentPlans

        Form {
            Section {
                LabeledContent(t.totalDebt) {
                    Text(t.money(debt.totalOwed))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                if let usage = debt.creditUsage {
                    LabeledContent(t.creditLimit, value: t.money(debt.creditLimit))
                    LabeledContent(t.creditUsed) {
                        UsageText(fraction: usage)
                    }
                    LabeledContent(t.availableCredit, value: t.money(max(debt.creditLimit - debt.totalOwed, 0)))
                }
                LabeledContent(t.nextDueDate, value: t.date(debt.nextDueDate))
            } header: {
                Text(t.summary)
                    .appFont(.headline)
            }

            Section {
                LabeledContent(t.currentBalance, value: t.money(debt.balance))
                LabeledContent(t.interestRateApprox, value: t.percent(debt.interestRate))
                LabeledContent(t.monthlyInterestApprox, value: t.money(debt.revolvingMonthlyInterest))
            } header: {
                Text(t.revolvingSection)
                    .appFont(.headline)
            }

            Section {
                if plans.isEmpty {
                    Text(t.noInstallments)
                        .foregroundStyle(.secondary)
                }
                ForEach(plans) { plan in
                    Button {
                        editingPlan = plan
                    } label: {
                        InstallmentRow(plan: plan)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(t.edit) { editingPlan = plan }
                        Button(t.delete, role: .destructive) { debt.deletePlan(plan) }
                    }
                }
                Button {
                    addingPlan = true
                } label: {
                    Label(t.addInstallment, systemImage: "plus")
                }
            } header: {
                Text(t.installmentsSection)
                    .appFont(.headline)
            } footer: {
                if !plans.isEmpty {
                    Text(t.installmentsFooter(balance: debt.installmentsRemaining, monthly: debt.installmentsMonthly))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $addingPlan) {
            InstallmentFormView(debt: debt)
        }
        .sheet(item: $editingPlan) { plan in
            InstallmentFormView(debt: debt, plan: plan)
        }
    }
}

private struct InstallmentRow: View {
    @Environment(\.l10n) private var t
    let plan: InstallmentPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Label(t.planKindName(plan.kind), systemImage: plan.kind.systemImage)
                    .appFont(.body, weight: .medium)
                if !plan.concept.isEmpty {
                    Text("· " + plan.concept)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(t.money(plan.remainingBalance()))
                    .monospacedDigit()
            }
            switch plan.kind {
            case .installments:
                installmentDetails
            case .balanceTransfer:
                transferDetails
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var rateText: String {
        plan.isInterestFree ? t.interestFree : t.percent(plan.annualRate)
    }

    @ViewBuilder
    private var installmentDetails: some View {
        let remaining = plan.remainingMonths()

        caption(
            [t.perMonth(plan.monthlyPayment), rateText]
                + (plan.totalAmount > 0 ? [t.totalAmount + " " + t.money(plan.totalAmount)] : [])
        )
        caption(remaining > 0
                ? [t.monthsLeft(remaining, of: plan.months), t.endsOn + " " + t.date(plan.endDate)]
                : [t.paidOff])
    }

    @ViewBuilder
    private var transferDetails: some View {
        let estimate = plan.transferEstimate()

        if estimate.isExpired {
            Text(t.promoExpired + " · " + t.date(plan.promoEndDate))
                .appFont(.subheadline)
                .foregroundStyle(.orange)
        } else {
            caption([t.dueShort + " " + t.date(plan.promoEndDate), t.monthsLeftShort(estimate.paymentsLeft), rateText])
            if let suggested = estimate.suggestedPayment {
                caption(
                    [t.suggestedShort(suggested)]
                        + (plan.minimumPayment > 0 ? [t.minimumShort + " " + t.money(plan.minimumPayment)] : [])
                )
            }
            if let leftover = estimate.leftoverPayingMinimum, leftover > 0 {
                Text(t.leftoverPayingMinimum(leftover))
                    .appFont(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func caption(_ parts: [String]) -> some View {
        Text(parts.joined(separator: " · "))
            .appFont(.subheadline)
            .foregroundStyle(.secondary)
    }
}
