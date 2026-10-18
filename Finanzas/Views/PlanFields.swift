import SwiftUI

/// Datos capturados de una compra a meses o transferencia de saldo, antes de guardarlos.
struct PlanDraft {
    var kind: PlanKind = .balanceTransfer
    var concept = ""
    var amountText = ""
    var months = 12
    var monthlyText = ""
    var rateText = ""
    var startDate = Date()
    var promoEndDate = Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date()
    var minimumText = ""
    var feeText = ""

    init() {}

    init(plan: InstallmentPlan) {
        kind = plan.kind
        concept = plan.concept
        amountText = editText(plan.totalAmount)
        months = plan.months
        monthlyText = editText(plan.monthlyPayment)
        rateText = editText(plan.annualRate)
        startDate = plan.startDate
        promoEndDate = plan.promoEndDate
        minimumText = editText(plan.minimumPayment)
        feeText = editText(plan.transferFeePercent)
    }

    var amount: Double { parseDecimal(amountText) }
    var monthly: Double { parseDecimal(monthlyText) }
    var rate: Double { parseDecimal(rateText) }
    var minimum: Double { parseDecimal(minimumText) }
    var feePercent: Double { parseDecimal(feeText) }
    var transferFee: Double { amount * feePercent / 100 }

    var isValid: Bool {
        switch kind {
        case .installments: return monthly > 0
        case .balanceTransfer: return amount > 0
        }
    }

    var pendingBalance: Double {
        switch kind {
        case .installments:
            let remaining = months - LoanMath.paymentsMade(start: startDate, months: months)
            return LoanMath.remainingBalance(payment: monthly, annualRate: rate, remainingMonths: remaining)
        case .balanceTransfer:
            return amount
        }
    }

    var transferEstimate: TransferEstimate {
        TransferEstimate(balance: amount, annualRate: rate, promoEnd: promoEndDate, minimumPayment: minimum)
    }

    func apply(to plan: InstallmentPlan) {
        plan.kind = kind
        plan.concept = concept.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.totalAmount = amount
        plan.annualRate = rate
        switch kind {
        case .installments:
            plan.months = months
            plan.monthlyPayment = monthly
            plan.startDate = startDate
        case .balanceTransfer:
            plan.promoEndDate = promoEndDate
            plan.minimumPayment = minimum
            plan.transferFeePercent = feePercent
        }
    }
}

/// Secciones del formulario para una compra a meses o transferencia de saldo.
struct PlanFields: View {
    @Environment(\.l10n) private var t
    @Binding var draft: PlanDraft

    var body: some View {
        Section {
            Picker(t.planType, selection: $draft.kind) {
                ForEach(PlanKind.allCases) { kind in
                    Text(t.planKindName(kind)).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch draft.kind {
            case .installments:
                installmentFields
            case .balanceTransfer:
                transferFields
            }
        } header: {
            Label(t.planKindName(draft.kind), systemImage: draft.kind.systemImage)
                .appFont(.headline)
        } footer: {
            Text(draft.kind == .installments ? t.planRateFooter : t.transferFooter)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }

        Section {
            switch draft.kind {
            case .installments:
                installmentPreview
            case .balanceTransfer:
                transferPreview
            }
        }
    }

    @ViewBuilder
    private var installmentFields: some View {
        TextRow(title: t.descriptionOptional, text: $draft.concept, prompt: t.conceptPlaceholder)
        DecimalField(title: t.totalAmount, text: $draft.amountText, prefix: t.currencySymbol)
        Stepper(value: $draft.months, in: 1...120) {
            Text(t.monthsCount(draft.months))
        }
        DecimalField(title: t.monthlyPayment, text: $draft.monthlyText, prefix: t.currencySymbol)
        DecimalField(title: t.annualRate, text: $draft.rateText, suffix: "%")
        DateField(title: t.startDate, date: $draft.startDate)
    }

    @ViewBuilder
    private var transferFields: some View {
        TextRow(title: t.descriptionOptional, text: $draft.concept, prompt: t.transferPlaceholder)
        DecimalField(title: t.transferBalance, text: $draft.amountText, prefix: t.currencySymbol)
        DecimalField(title: t.promoRate, text: $draft.rateText, suffix: "%")
        DecimalField(title: t.transferFeeOptional, text: $draft.feeText, suffix: "%")
        DateField(title: t.promoEndDate, date: $draft.promoEndDate)
        DecimalField(title: t.minimumPaymentOptional, text: $draft.minimumText, prefix: t.currencySymbol)
    }

    @ViewBuilder
    private var installmentPreview: some View {
        LabeledContent(t.endsOn, value: t.date(LoanMath.endDate(start: draft.startDate, months: draft.months)))
        LabeledContent(t.remainingBalance, value: t.money(draft.pendingBalance))
    }

    @ViewBuilder
    private var transferPreview: some View {
        let estimate = draft.transferEstimate

        if draft.transferFee > 0 {
            LabeledContent(t.transferFee, value: t.money(draft.transferFee))
        }
        if estimate.isExpired {
            Label(t.promoExpired, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        } else {
            LabeledContent(t.timeLeft, value: t.monthsCount(estimate.paymentsLeft))
            if let suggested = estimate.suggestedPayment {
                LabeledContent(t.suggestedPayment, value: t.perMonth(suggested))
            }
            if let leftover = estimate.leftoverPayingMinimum, leftover > 0 {
                Text(t.leftoverPayingMinimum(leftover))
                    .foregroundStyle(.orange)
            }
        }
    }
}
