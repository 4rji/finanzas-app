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
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]

    let kind: DebtKind
    let debt: Debt?

    @State private var name: String
    @State private var balanceText: String
    @State private var rateText: String
    @State private var paymentText: String
    @State private var limitText: String
    @State private var dueDay: Int
    @State private var insuranceText: String

    // Pago automático desde una cuenta de cheques.
    @State private var autoPay: Bool
    @State private var payAccount: Account?

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
        _limitText = State(initialValue: editText(debt?.creditLimit ?? 0))
        _dueDay = State(initialValue: debt?.paymentDueDay ?? 1)
        _insuranceText = State(initialValue: editText(debt?.insuranceAmount ?? 0))
        _autoPay = State(initialValue: debt?.autoPayment != nil)
        _payAccount = State(initialValue: debt?.autoPayment?.account)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNewCard: Bool { debt == nil && kind == .creditCard }
    private var includesPlan: Bool { isNewCard && balanceType != .revolving }

    private var accounts: [Account] { allAccounts.checking }
    private var selectedPayAccount: Account? { payAccount ?? accounts.first }
    private var monthly: Double { parseDecimal(paymentText) }

    private var canSave: Bool {
        !trimmedName.isEmpty
            && (!includesPlan || planDraft.isValid)
            && (!autoPay || (monthly > 0 && selectedPayAccount != nil))
    }

    /// El calendario del pago automático se reinicia si es nuevo o si cambió el día.
    private var reschedulesAutoPay: Bool {
        guard let debt, debt.autoPayment != nil else { return true }
        return dueDay != debt.paymentDueDay
    }

    /// Primer día de pago después de hoy, para no cobrar dos veces si hoy ya se pagó a mano.
    private var firstAutoPayDate: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Debt.nextDate(onDay: dueDay, onOrAfter: tomorrow)
    }

    private var nextAutoPayDate: Date {
        if !reschedulesAutoPay, let plan = debt?.autoPayment { return plan.nextPayDate }
        return firstAutoPayDate
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save) {
            switch kind {
            case .creditCard:
                cardSections
            case .mortgage, .autoLoan, .studentLoan:
                loanSections
            }
            autoPaySection
        }
    }

    private var header: some View {
        Label(t.kindName(kind), systemImage: kind.systemImage)
            .appFont(.headline)
    }

    @ViewBuilder
    private var cardSections: some View {
        Section {
            TextRow(title: t.name, text: $name, prompt: t.namePlaceholder(kind))
            if !isNewCard {
                DecimalField(title: t.revolvingSection, text: $balanceText, prefix: t.currencySymbol)
            }
            DecimalField(title: t.creditLimit, text: $limitText, prefix: t.currencySymbol)
            DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
            Picker(t.paymentDueDay, selection: $dueDay) {
                ForEach(1...31, id: \.self) { day in
                    Text(String(day)).tag(day)
                }
            }
            DecimalField(title: t.cardPlannedPayment, text: $paymentText, prefix: t.currencySymbol)
        } header: {
            header
        } footer: {
            Text(isNewCard ? t.cardPlannedPaymentFooter : t.cardFormFooter + " " + t.cardPlannedPaymentFooter)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }

        if isNewCard {
            Section {
                Picker(t.balanceTypeQuestion, selection: $balanceType) {
                    ForEach(CardBalanceType.allCases) { type in
                        Text(t.balanceTypeName(type)).tag(type)
                    }
                }
                #if os(macOS)
                .pickerStyle(.radioGroup)
                #endif

                if balanceType != .installments {
                    DecimalField(title: t.revolvingSection, text: $balanceText, prefix: t.currencySymbol)
                }
            } header: {
                Text(t.balanceSection)
                    .appFont(.headline)
            } footer: {
                Text(t.balanceTypeFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if balanceType != .revolving {
                PlanFields(draft: $planDraft)
            }
        }
    }

    @ViewBuilder
    private var loanSections: some View {
        Section {
            TextRow(title: t.name, text: $name, prompt: t.namePlaceholder(kind))
            DecimalField(title: t.remainingBalance, text: $balanceText, prefix: t.currencySymbol)
            DecimalField(title: t.interestRateApprox, text: $rateText, suffix: "%")
            DecimalField(title: t.monthlyPayment, text: $paymentText, prefix: t.currencySymbol)
        } header: {
            header
        } footer: {
            Text(t.approxNote)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }

        // El seguro del auto es solo una nota: no entra en el pago ni en el total.
        if kind == .autoLoan {
            Section {
                DecimalField(title: t.insuranceAmount, text: $insuranceText, prefix: t.currencySymbol)
            } header: {
                Label(t.insurance, systemImage: "shield")
                    .appFont(.headline)
            } footer: {
                Text(t.insuranceFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// La casilla solo aparece si hay una cuenta de cheques de donde sacar el pago.
    private var autoPaySection: some View {
        Section {
            if accounts.isEmpty {
                Label(t.autoPayNeedsAccount, systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            } else {
                Toggle(t.autoPayToggle, isOn: $autoPay)
                    .checkboxStyle()
                if autoPay {
                    AccountPicker(accounts: accounts, selection: $payAccount)
                    if kind != .creditCard {
                        Picker(t.paymentDay, selection: $dueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text(String(day)).tag(day)
                            }
                        }
                    }
                    if monthly > 0 {
                        LabeledContent(t.nextAutoPayment, value: t.date(nextAutoPayDate))
                    } else {
                        Label(t.autoPayNeedsAmount, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }
        } header: {
            Label(t.autoPay, systemImage: "arrow.triangle.2.circlepath")
                .appFont(.headline)
        } footer: {
            if !accounts.isEmpty {
                Text(t.autoPayFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        let rescheduleAutoPay = reschedulesAutoPay
        let target: Debt
        if let debt {
            target = debt
        } else {
            target = Debt(name: trimmedName, kind: kind)
            context.insert(target)
        }

        target.name = trimmedName
        target.interestRate = parseDecimal(rateText)

        target.paymentDueDay = dueDay
        target.monthlyPayment = monthly

        switch kind {
        case .creditCard:
            target.creditLimit = parseDecimal(limitText)
            target.balance = (isNewCard && balanceType == .installments) ? 0 : parseDecimal(balanceText)
            if includesPlan {
                let plan = InstallmentPlan(kind: planDraft.kind)
                context.insert(plan)
                planDraft.apply(to: plan)
                if target.plans == nil { target.plans = [] }
                target.plans?.append(plan)
            }
        case .mortgage, .autoLoan, .studentLoan:
            target.balance = parseDecimal(balanceText)
            if kind == .autoLoan {
                target.insuranceAmount = parseDecimal(insuranceText)
            }
        }

        if autoPay, let account = selectedPayAccount, monthly > 0 {
            let plan: RecurringPayment
            if let existing = target.autoPayment {
                plan = existing
            } else {
                plan = RecurringPayment()
                context.insert(plan)
                plan.debt = target
            }
            plan.account = account
            plan.amount = monthly
            if rescheduleAutoPay {
                plan.reschedule(start: firstAutoPayDate)
            }
        } else if !autoPay, let existing = target.autoPayment {
            context.delete(existing)
        }
        try? context.save()
        RecurringDeposits.update(in: context)
    }
}
