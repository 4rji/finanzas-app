import SwiftUI

struct CreditCardDetailView: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    @State private var addingPlan = false
    @State private var editingPlan: InstallmentPlan?

    var body: some View {
        let plans = debt.installmentPlans

        Form {
            Section(t.summary) {
                LabeledContent(t.totalDebt) {
                    Text(t.money(debt.totalOwed))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                LabeledContent(t.nextDueDate, value: t.date(debt.nextDueDate))
            }

            Section(t.revolvingSection) {
                LabeledContent(t.currentBalance, value: t.money(debt.balance))
                LabeledContent(t.interestRateApprox, value: t.percent(debt.interestRate))
                LabeledContent(t.monthlyInterestApprox, value: t.money(debt.revolvingMonthlyInterest))
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
            } footer: {
                if !plans.isEmpty {
                    Text(t.installmentsFooter(balance: debt.installmentsRemaining, monthly: debt.installmentsMonthly))
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
            HStack {
                Label(plan.concept.isEmpty ? t.planKindName(plan.kind) : plan.concept, systemImage: plan.kind.systemImage)
                    .font(.body.weight(.medium))
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
                .font(.caption)
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
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func caption(_ parts: [String]) -> some View {
        Text(parts.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
