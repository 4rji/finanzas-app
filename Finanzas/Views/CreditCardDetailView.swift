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
        let remaining = plan.remainingMonths()

        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(plan.concept.isEmpty ? t.installmentDefaultName : plan.concept)
                    .font(.body.weight(.medium))
                Spacer()
                Text(t.money(plan.remainingBalance()))
                    .monospacedDigit()
            }
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(remaining > 0
                 ? t.monthsLeft(remaining, of: plan.months) + " · " + t.endsOn + " " + t.date(plan.endDate)
                 : t.paidOff)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var details: String {
        var parts = [
            t.perMonth(plan.monthlyPayment),
            plan.isInterestFree ? t.interestFree : t.percent(plan.annualRate),
        ]
        if plan.totalAmount > 0 {
            parts.append(t.totalAmount + " " + t.money(plan.totalAmount))
        }
        return parts.joined(separator: " · ")
    }
}
