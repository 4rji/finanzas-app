import SwiftUI
import SwiftData

/// Alta o edición de una compra a meses (con o sin intereses).
struct InstallmentFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let debt: Debt
    let plan: InstallmentPlan?

    @State private var concept: String
    @State private var amountText: String
    @State private var months: Int
    @State private var monthlyText: String
    @State private var rateText: String
    @State private var startDate: Date
    @State private var includedInBalance: Bool

    init(debt: Debt, plan: InstallmentPlan? = nil) {
        self.debt = debt
        self.plan = plan
        _concept = State(initialValue: plan?.concept ?? "")
        _amountText = State(initialValue: editText(plan?.totalAmount ?? 0))
        _months = State(initialValue: plan?.months ?? 12)
        _monthlyText = State(initialValue: editText(plan?.monthlyPayment ?? 0))
        _rateText = State(initialValue: editText(plan?.annualRate ?? 0))
        _startDate = State(initialValue: plan?.startDate ?? Date())
        _includedInBalance = State(initialValue: plan == nil && debt.balance > 0)
    }

    private var monthly: Double { parseDecimal(monthlyText) }
    private var rate: Double { parseDecimal(rateText) }

    /// Solo al agregar una compra nueva a una tarjeta que ya tiene saldo revolvente.
    private var asksIfIncluded: Bool { plan == nil && debt.balance > 0 }

    var body: some View {
        FormSheet(canSave: monthly > 0, onSave: save, onDelete: plan == nil ? nil : delete) {
            Section {
                TextRow(title: t.concept, text: $concept, prompt: t.conceptPlaceholder)
                DecimalField(title: t.totalAmount, text: $amountText, prefix: t.currencySymbol)
                Stepper(value: $months, in: 1...120) {
                    Text(t.monthsCount(months))
                }
                DecimalField(title: t.monthlyPayment, text: $monthlyText, prefix: t.currencySymbol)
                DecimalField(title: t.annualRate, text: $rateText, suffix: "%")
                DatePicker(t.startDate, selection: $startDate, displayedComponents: .date)
            } header: {
                Label(t.installmentsSection, systemImage: "calendar")
                    .font(.headline)
            } footer: {
                Text(t.planRateFooter)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent(t.endsOn, value: t.date(LoanMath.endDate(start: startDate, months: months)))
            }

            if asksIfIncluded {
                Section {
                    Toggle(t.includedInBalance, isOn: $includedInBalance)
                } footer: {
                    Text(t.includedInBalanceFooter)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func save() {
        let trimmed = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = parseDecimal(amountText)

        if let plan {
            plan.concept = trimmed
            plan.totalAmount = amount
            plan.months = months
            plan.monthlyPayment = monthly
            plan.annualRate = rate
            plan.startDate = startDate
        } else {
            let newPlan = InstallmentPlan(
                concept: trimmed,
                totalAmount: amount,
                months: months,
                monthlyPayment: monthly,
                annualRate: rate,
                startDate: startDate
            )
            context.insert(newPlan)
            if debt.plans == nil { debt.plans = [] }
            debt.plans?.append(newPlan)

            if asksIfIncluded && includedInBalance {
                debt.balance = max(debt.balance - newPlan.remainingBalance(), 0)
            }
        }
        try? context.save()
    }

    private func delete() {
        if let plan { debt.deletePlan(plan) }
    }
}
