import SwiftUI
import SwiftData

private struct PayoffItem: Identifiable {
    let debt: Debt
    let estimate: PayoffEstimate

    var id: PersistentIdentifier { debt.persistentModelID }
}

/// Todas las deudas a la vista como fichas, cada una con el color de su categoría, con su saldo,
/// pago y fecha estimada de liquidación.
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
                        VStack(alignment: .leading, spacing: 16 * scale) {
                            hero(items)
                            VStack(alignment: .leading, spacing: 10 * scale) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(t.debts)
                                        .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                                        .accessibilityAddTraits(.isHeader)
                                    Spacer(minLength: 8)
                                    Text(t.debtCount(items.count))
                                        .appFont(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 136 * scale), spacing: 12)], spacing: 12) {
                                    ForEach(items) { item in
                                        NavigationLink {
                                            DebtDetailView(debt: item.debt)
                                                .backButton(t.timeToPayoff)
                                        } label: {
                                            PayoffTile(debt: item.debt, estimate: item.estimate)
                                        }
                                        .buttonStyle(PressableStyle())
                                    }
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
                        .padding(.horizontal, compact ? 16 : 28)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
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
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return VStack(alignment: .leading, spacing: 14 * scale) {
            HStack(spacing: 12) {
                Image(systemName: date == nil ? summaryStatusIcon(items) : "calendar.badge.checkmark")
                    .font(.system(size: 17 * scale, weight: .semibold))
                    .frame(width: 38 * scale, height: 38 * scale)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(date == nil ? t.estimateSection : t.debtFreeApprox)
                        .appFont(.subheadline, weight: .semibold)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(date.map { t.monthYearLong($0) } ?? summaryStatus(items))
                        .font(.system(size: 26 * scale, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 1)
            HStack(alignment: .top, spacing: 16) {
                metric(t.totalDebt, value: t.money(debts.countedTotal))
                metric(t.monthlyPayments, value: t.perMonth(items.reduce(0) { $0 + $1.estimate.payment }))
            }
        }
        .foregroundStyle(.white)
        .padding(18 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: ThemeTint.mint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 19 * scale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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

/// Ficha de una deuda con el color de su categoría: saldo, tiempo que falta, pago y fecha.
private struct PayoffTile: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let debt: Debt
    let estimate: PayoffEstimate

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let tint = debt.kind.tint

        VStack(alignment: .leading, spacing: 10 * scale) {
            HStack(spacing: 8) {
                Image(systemName: debt.kind.systemImage)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .frame(width: 28 * scale, height: 28 * scale)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)
                Text(debt.name)
                    .appFont(.body, weight: .semibold)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if hasExpiredPromo {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .appFont(.subheadline)
                        .accessibilityLabel(t.promoExpired)
                        .help(t.promoExpired)
                }
            }
            Text(t.money(debt.totalOwed))
                .font(.system(size: 24 * scale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            VStack(alignment: .leading, spacing: 3) {
                Label(statusText, systemImage: statusIcon)
                    .appFont(.subheadline, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                // Siempre ocupa su renglón para que todas las fichas midan lo mismo.
                Text(detailText ?? " ")
                    .appFont(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(.white)
        .padding(14 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: tint.solid(scheme).opacity(0.16), radius: 10, y: 6)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }

    private var hasExpiredPromo: Bool {
        debt.installmentPlans.contains { $0.kind == .balanceTransfer && $0.totalAmount > 0 && $0.transferEstimate().isExpired }
    }

    private var statusText: String {
        switch estimate.status {
        case .paidOff: return t.paidOff
        case .months(let months): return t.duration(months: months)
        case .noPayment: return t.noPaymentSet
        case .paymentTooLow: return t.paymentNotEnough
        }
    }

    private var statusIcon: String {
        switch estimate.status {
        case .paidOff: return "checkmark.circle.fill"
        case .months: return "clock"
        case .noPayment, .paymentTooLow: return "exclamationmark.circle.fill"
        }
    }

    /// "$300/mes · mar 2028"; nil si no tiene pago.
    private var detailText: String? {
        guard estimate.payment > 0 else { return nil }
        guard case .months(let months) = estimate.status else { return t.perMonth(estimate.payment) }
        return t.perMonth(estimate.payment) + " · " + t.monthYear(LoanMath.endDate(start: Date(), months: months))
    }
}
