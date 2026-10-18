import SwiftUI
import SwiftData

/// Cómo está el saldo de una tarjeta nueva.
enum CardBalanceType: String, CaseIterable, Identifiable {
    case revolving
    case installments
    case both

    var id: String { rawValue }
}

/// Alta o edición de una deuda. Los campos cambian según el tipo.
struct DebtFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let kind: DebtKind
    let debt: Debt?

    @State private var name: String
    @State private var balanceText: String
    @State private var rateText: String
    @State private var paymentText: String
    @State private var dueDay: Int

    // Solo tarjeta nueva: saldo revolvente y/o meses sin intereses.
    @State private var balanceType: CardBalanceType = .revolving
    @State private var planDraft = PlanDraft()

    init(kind: DebtKind, debt: Debt? = nil) {
        self.kind = kind
        self.debt = debt
        _name = State(initialValue: debt?.name ?? "")
        _balanceText = State(initialValue: editText(debt?.balance ?? 0))
        _rateText = State(initialValue: editText(debt?.interestRate ?? 0))
        _paymentText = State(initialValue: editText(debt?.monthlyPayment ?? 0))
        _dueDay = State(initialValue: debt?.paymentDueDay ?? 1)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNewCard: Bool { debt == nil && kind == .creditCard }
    private var includesPlan: Bool { isNewCard && balanceType != .revolving }

    private var canSave: Bool {
        !trimmedName.isEmpty && (!includesPlan || planDraft.isValid)
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save) {
            switch kind {
            case .creditCard:
                cardSections
            case .mortgage, .studentLoan:
                loanSection
            }
        }
    }

    private var header: some View {
        Label(t.kindName(kind), systemImage: kind.systemImage)
            .font(.headline)
    }

    @ViewBuilder
    private var cardSections: some View {
        Section {
            TextRow(title: t.name, text: $name, prompt: t.namePlaceholder(kind))
            if !isNewCard {
                DecimalField(title: t.revolvingSection, text: $balanceText, prefix: t.currencySymbol)
            }
            DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
            Picker(t.paymentDueDay, selection: $dueDay) {
                ForEach(1...31, id: \.self) { day in
                    Text(String(day)).tag(day)
                }
            }
        } header: {
            header
        } footer: {
            if !isNewCard {
                Text(t.cardFormFooter)
                    .foregroundStyle(.secondary)
            }
        }

        if isNewCard {
            Section {
                Picker(t.balanceTypeQuestion, selection: $balanceType) {
                    ForEach(CardBalanceType.allCases) { type in
                        Text(t.balanceTypeName(type)).tag(type)
                    }
                }
                .pickerStyle(.radioGroup)

                if balanceType != .installments {
                    DecimalField(title: t.revolvingSection, text: $balanceText, prefix: t.currencySymbol)
                }
            } header: {
                Text(t.balanceSection)
            } footer: {
                Text(t.balanceTypeFooter)
                    .foregroundStyle(.secondary)
            }

            if balanceType != .revolving {
                PlanFields(draft: $planDraft)
            }
        }
    }

    private var loanSection: some View {
        Section {
            TextRow(title: t.name, text: $name, prompt: t.namePlaceholder(kind))
            DecimalField(title: t.remainingBalance, text: $balanceText, prefix: t.currencySymbol)
            DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
            DecimalField(title: t.monthlyPayment, text: $paymentText, prefix: t.currencySymbol)
        } header: {
            header
        } footer: {
            Text(t.approxNote)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        let target: Debt
        if let debt {
            target = debt
        } else {
            target = Debt(name: trimmedName, kind: kind)
            context.insert(target)
        }

        target.name = trimmedName
        target.interestRate = parseDecimal(rateText)

        switch kind {
        case .creditCard:
            target.paymentDueDay = dueDay
            target.balance = (isNewCard && balanceType == .installments) ? 0 : parseDecimal(balanceText)
            if includesPlan {
                let plan = InstallmentPlan(kind: planDraft.kind)
                context.insert(plan)
                planDraft.apply(to: plan)
                if target.plans == nil { target.plans = [] }
                target.plans?.append(plan)
            }
        case .mortgage, .studentLoan:
            target.balance = parseDecimal(balanceText)
            target.monthlyPayment = parseDecimal(paymentText)
        }
        try? context.save()
    }
}
