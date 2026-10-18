import SwiftUI
import SwiftData

/// Alta o edición de una compra a meses o transferencia de saldo.
struct InstallmentFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let debt: Debt
    let plan: InstallmentPlan?

    @State private var draft: PlanDraft
    @State private var includedInBalance: Bool

    init(debt: Debt, plan: InstallmentPlan? = nil) {
        self.debt = debt
        self.plan = plan
        _draft = State(initialValue: plan.map(PlanDraft.init(plan:)) ?? PlanDraft())
        _includedInBalance = State(initialValue: plan == nil && debt.balance > 0)
    }

    /// Solo al agregar uno nuevo a una tarjeta que ya tiene saldo revolvente.
    private var asksIfIncluded: Bool { plan == nil && debt.balance > 0 }

    var body: some View {
        FormSheet(canSave: draft.isValid, onSave: save, onDelete: plan == nil ? nil : delete) {
            PlanFields(draft: $draft)

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
        if let plan {
            draft.apply(to: plan)
        } else {
            let newPlan = InstallmentPlan(kind: draft.kind)
            context.insert(newPlan)
            draft.apply(to: newPlan)
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
