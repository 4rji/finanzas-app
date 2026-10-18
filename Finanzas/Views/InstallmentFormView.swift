import SwiftUI
import SwiftData

/// Alta o edición de una compra a meses (con o sin intereses).
struct InstallmentFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let debt: Debt
    let plan: InstallmentPlan?

    @State private var concept: String
    @State private var amountText: String
    @State private var months: Int
    @State private var rateText: String
    @State private var startDate: Date

    init(debt: Debt, plan: InstallmentPlan? = nil) {
        self.debt = debt
        self.plan = plan
        _concept = State(initialValue: plan?.concept ?? "")
        _amountText = State(initialValue: editText(plan?.totalAmount ?? 0))
        _months = State(initialValue: plan?.months ?? 12)
        _rateText = State(initialValue: editText(plan?.annualRate ?? 0))
        _startDate = State(initialValue: plan?.startDate ?? Date())
    }

    private var amount: Double { parseDecimal(amountText) }
    private var rate: Double { parseDecimal(rateText) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextRow(title: t.concept, text: $concept, prompt: t.conceptPlaceholder)
                    DecimalField(title: t.totalAmount, text: $amountText, prefix: t.currencySymbol)
                    Stepper(value: $months, in: 1...120) {
                        Text(t.monthsCount(months))
                    }
                    DecimalField(title: t.annualRate, text: $rateText, suffix: "%")
                    DatePicker(t.startDate, selection: $startDate, displayedComponents: .date)
                } header: {
                    Text(t.installmentsSection)
                } footer: {
                    Text(t.planRateFooter)
                }

                Section {
                    LabeledContent(
                        t.monthlyPayment,
                        value: t.money(LoanMath.payment(principal: amount, annualRate: rate, months: months))
                    )
                    LabeledContent(t.endsOn, value: t.date(LoanMath.endDate(start: startDate, months: months)))
                }
            }
            .formStyle(.grouped)
            .navigationTitle(t.installmentsSection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t.save) {
                        save()
                        dismiss()
                    }
                    .disabled(amount <= 0)
                }
            }
        }
        .macSheetSize()
    }

    private func save() {
        let trimmed = concept.trimmingCharacters(in: .whitespacesAndNewlines)

        if let plan {
            plan.concept = trimmed
            plan.totalAmount = amount
            plan.months = months
            plan.annualRate = rate
            plan.startDate = startDate
        } else {
            let newPlan = InstallmentPlan(
                concept: trimmed,
                totalAmount: amount,
                months: months,
                annualRate: rate,
                startDate: startDate
            )
            context.insert(newPlan)
            if debt.plans == nil { debt.plans = [] }
            debt.plans?.append(newPlan)
        }
        try? context.save()
    }
}
