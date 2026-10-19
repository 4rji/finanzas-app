import SwiftUI
import SwiftData

private struct PayoffItem: Identifiable {
    let debt: Debt
    let estimate: PayoffEstimate

    var id: PersistentIdentifier { debt.persistentModelID }
}

/// Cada deuda con su saldo, pago y fechas estimadas de liquidación y promociones.
struct PayoffView: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    @Query(sort: \Debt.createdAt) private var debts: [Debt]

    var body: some View {
        let items = DebtKind.allCases
            .flatMap { kind in debts.filter { $0.kind == kind } }
            .map { PayoffItem(debt: $0, estimate: $0.payoffEstimate()) }

        Group {
            if debts.isEmpty {
                ContentUnavailableView(t.noDebtsTitle, systemImage: "tray", description: Text(t.noDebtsMessage))
            } else {
                GeometryReader { geometry in
                    let compact = geometry.size.width < 620 * scale
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22 * scale) {
                            hero(items)
                            summary(items, compact: compact)
                            VStack(alignment: .leading, spacing: 13 * scale) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(t.debts)
                                        .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                                        .accessibilityAddTraits(.isHeader)
                                    Spacer(minLength: 8)
                                    Text(t.debtCount(items.count))
                                        .appFont(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(items) { item in
                                    NavigationLink {
                                        DebtDetailView(debt: item.debt)
                                    } label: {
                                        PayoffRow(debt: item.debt, estimate: item.estimate, compact: compact)
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                            Label {
                                Text(t.payoffFooter)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "info.circle")
                            }
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, compact ? 18 : 28)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .screenBackground()
        .navigationTitle(t.timeToPayoff)
        .hideAmountsToolbar()
    }

    private func hero(_ items: [PayoffItem]) -> some View {
        let date = debtFreeDate(items.map(\.estimate))
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        return VStack(alignment: .leading, spacing: 16 * scale) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 20 * scale, weight: .semibold))
                    .frame(width: 44 * scale, height: 44 * scale)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                Text(date == nil ? t.estimateSection : t.debtFreeApprox)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text(date.map { t.monthYearLong($0) } ?? t.timeToPayoff)
                .font(.system(size: 36 * scale, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if date != nil {
                Text(t.payoffHint)
                    .appFont(.body)
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Label(summaryStatus(items), systemImage: summaryStatusIcon(items))
                    .appFont(.subheadline, weight: .medium)
                    .padding(12 * scale)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .foregroundStyle(.white)
        .padding(24 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .trailing) {
                LinearGradient(colors: ThemeTint.mint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .stroke(.white.opacity(0.05), lineWidth: 38)
                    .frame(width: 240, height: 240)
                    .offset(x: 100, y: 80)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }

    private func summary(_ items: [PayoffItem], compact: Bool) -> some View {
        let layout = compact ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            PayoffMetric(title: t.totalDebt, value: t.money(debts.countedTotal), systemImage: "creditcard", tint: .peach)
            PayoffMetric(title: t.monthlyPayments, value: t.perMonth(items.reduce(0) { $0 + $1.estimate.payment }), systemImage: "arrow.triangle.2.circlepath", tint: .mint)
        }
    }

    private func summaryStatus(_ items: [PayoffItem]) -> String {
        if items.contains(where: { if case .noPayment = $0.estimate.status { return true }; return false }) {
            return t.noPaymentSet
        }
        if items.contains(where: { if case .paymentTooLow = $0.estimate.status { return true }; return false }) {
            return t.paymentNotEnough
        }
        return t.paidOff
    }

    private func summaryStatusIcon(_ items: [PayoffItem]) -> String {
        items.allSatisfy { if case .paidOff = $0.estimate.status { return true }; return false }
            ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    /// Cuando se liquida la última deuda; nil si alguna no tiene fecha estimada.
    private func debtFreeDate(_ estimates: [PayoffEstimate]) -> Date? {
        let months = estimates.compactMap(\.months)
        guard months.count == estimates.count, let last = months.max(), last > 0 else { return nil }
        return LoanMath.endDate(start: Date(), months: last)
    }
}

private struct PayoffMetric: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let title: String
    let value: String
    let systemImage: String
    let tint: ThemeTint

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                icon
                metricText
                    .frame(minWidth: 160 * scale, alignment: .leading)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 14) {
                icon
                metricText
            }
        }
        .padding(20 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scheme == .dark ? Color(hex: 0x1A261F) : .white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        IconTile(systemImage: systemImage, tint: tint, size: 38)
            .accessibilityHidden(true)
    }

    private var metricText: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 26 * scale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
    }
}

private struct PayoffRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let debt: Debt
    let estimate: PayoffEstimate
    let compact: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        VStack(alignment: .leading, spacing: 18 * scale) {
            HStack(spacing: 12) {
                IconTile(systemImage: debt.kind.systemImage, tint: debt.kind.tint, size: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(debt.name)
                        .appFont(.headline, weight: .semibold)
                        .foregroundStyle(.primary)
                    Text(t.kindName(debt.kind))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(t.remainingBalance)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                Text(t.money(debt.totalOwed))
                    .font(.system(size: 30 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            status
            if estimate.payment > 0 {
                let layout = compact ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14)) : AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                layout {
                    detail(title: t.monthlyPayment, value: t.perMonth(estimate.payment))
                    if case .months(let months) = estimate.status {
                        detail(title: t.payoffDate, value: t.monthYearLong(LoanMath.endDate(start: Date(), months: months)))
                    }
                }
            }
            if !transfers.isEmpty || debt.autoPayment?.account != nil || debt.insuranceAmount > 0 {
                Divider().overlay(Color.primary.opacity(0.03))
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(transfers) { plan in
                        promo(plan)
                    }
                    if let plan = debt.autoPayment, let account = plan.account {
                        note(t.autoPay + ": " + t.autoPaySummary(amount: plan.amount, account: account.name, next: plan.nextPayDate), icon: "arrow.triangle.2.circlepath")
                    }
                    if debt.insuranceAmount > 0 {
                        note(t.insuranceNote(debt.insuranceAmount), icon: "shield")
                    }
                }
            }
        }
        .padding(22 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scheme == .dark ? Color(hex: 0x1A261F) : .white, in: shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.07), lineWidth: 1))
        .contentShape(shape)
    }

    private var transfers: [InstallmentPlan] {
        debt.installmentPlans.filter { $0.kind == .balanceTransfer && $0.totalAmount > 0 }
    }

    @ViewBuilder
    private var status: some View {
        switch estimate.status {
        case .paidOff:
            badge(t.paidOff, icon: "checkmark.circle.fill", color: ThemeTint.mint.solid(scheme))
        case .months(let months):
            badge(t.duration(months: months), icon: "clock", color: debt.kind.tint.solid(scheme))
        case .noPayment:
            badge(t.noPaymentSet, icon: "exclamationmark.circle.fill", color: warningColor)
        case .paymentTooLow:
            badge(t.paymentNotEnough, icon: "exclamationmark.circle.fill", color: warningColor)
        }
    }

    private var warningColor: Color {
        Color(hex: scheme == .dark ? 0xF3B36D : 0x9B5416)
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .appFont(.subheadline, weight: .semibold)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(scheme == .dark ? 0.13 : 0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func detail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .appFont(.body, weight: .semibold)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func promo(_ plan: InstallmentPlan) -> some View {
        if plan.transferEstimate().isExpired {
            note(t.promoExpired + " · " + t.date(plan.promoEndDate), icon: "exclamationmark.circle", color: warningColor)
        } else {
            note(t.promoEnds(plan.promoEndDate) + " · " + t.monthsLeftShort(plan.remainingMonths()), icon: "calendar")
        }
    }

    private func note(_ text: String, icon: String, color: Color = .secondary) -> some View {
        Label(text, systemImage: icon)
            .appFont(.subheadline)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}
