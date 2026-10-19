import SwiftUI
import SwiftData
import Charts

private struct PayoffItem: Identifiable {
    let debt: Debt
    let estimate: PayoffEstimate

    var id: PersistentIdentifier { debt.persistentModelID }
}

/// Cuándo se termina de pagar cada deuda: una línea de tiempo y una tarjeta ancha por deuda, con el
/// color de su categoría, su saldo, pago y fecha estimada de liquidación.
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
                            timeline(items)
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
                                // Una columna en iPhone; dos en pantallas anchas.
                                let columns = Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: compact ? 1 : 2)
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(items) { item in
                                        NavigationLink {
                                            DebtDetailView(debt: item.debt)
                                                .backButton(t.timeToPayoff)
                                        } label: {
                                            PayoffCard(debt: item.debt, estimate: item.estimate)
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

    /// Una barra por deuda, de hoy a su fecha estimada de liquidación.
    private func timeline(_ items: [PayoffItem]) -> some View {
        let now = Date()
        let rows = timelineRows(items, now: now)
        let missing = items.filter { $0.estimate.months == nil }.count
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let last = rows.map(\.end).max() ?? now
        // Espacio a la derecha para el tiempo que se escribe al final de cada barra.
        let end = last.addingTimeInterval(max(last.timeIntervalSince(now) * 0.3, 86_400 * 60))
        let format: Date.FormatStyle = last.timeIntervalSince(now) > 86_400 * 365 * 2
            ? .dateTime.year()
            : .dateTime.month(.abbreviated).year(.twoDigits)

        return VStack(alignment: .leading, spacing: 12 * scale) {
            Text(t.payoffTimeline)
                .font(.system(size: 17 * scale, weight: .bold, design: .rounded))
                .accessibilityAddTraits(.isHeader)
            if !rows.isEmpty {
                Chart(rows) { row in
                    BarMark(
                        xStart: .value(t.dateLabel, now),
                        xEnd: .value(t.payoffDate, row.end),
                        y: .value(t.debts, row.label),
                        height: .ratio(0.62)
                    )
                    .foregroundStyle(row.kind.tint.solid(scheme))
                    .cornerRadius(6)
                    .annotation(position: .trailing, alignment: .leading, spacing: 6) {
                        Text(t.durationShort(months: row.months))
                            .appFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXScale(domain: now...end)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.primary.opacity(0.06))
                        AxisValueLabel(format: format)
                    }
                }
                .frame(height: CGFloat(rows.count) * 40 * scale + 30)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(t.payoffTimeline)
                .accessibilityValue(rows.map { $0.label + ", " + t.duration(months: $0.months) }.joined(separator: "; "))
            }
            if missing > 0 {
                Label(t.timelineMissing(missing), systemImage: "exclamationmark.circle")
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scheme == .dark ? Color(hex: 0x1A261F) : .white, in: shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }

    /// Solo las deudas con fecha estimada. Si dos se llaman igual, la segunda lleva "(2)" para que
    /// cada una tenga su propia barra.
    private func timelineRows(_ items: [PayoffItem], now: Date) -> [TimelineRow] {
        var rows: [TimelineRow] = []
        var seen: [String: Int] = [:]
        for item in items {
            guard case .months(let months) = item.estimate.status, months > 0 else { continue }
            let name = item.debt.name
            let count = (seen[name] ?? 0) + 1
            seen[name] = count
            rows.append(TimelineRow(
                id: rows.count,
                label: count == 1 ? name : name + " (\(count))",
                kind: item.debt.kind,
                months: months,
                end: LoanMath.endDate(start: now, months: months)
            ))
        }
        return rows
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

private struct TimelineRow: Identifiable {
    let id: Int
    let label: String
    let kind: DebtKind
    let months: Int
    let end: Date
}

/// Tarjeta ancha de una deuda con el color de su categoría: saldo, tiempo que falta, pago, fecha y
/// avisos de promociones y pago automático.
private struct PayoffCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let debt: Debt
    let estimate: PayoffEstimate

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        let tint = debt.kind.tint

        VStack(alignment: .leading, spacing: 16 * scale) {
            HStack(spacing: 12) {
                Image(systemName: debt.kind.systemImage)
                    .font(.system(size: 19 * scale, weight: .semibold))
                    .frame(width: 42 * scale, height: 42 * scale)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(debt.name)
                        .font(.system(size: 19 * scale, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    Text(t.kindName(debt.kind))
                        .appFont(.subheadline, weight: .medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityHidden(true)
            }
            // Saldo y pago lado a lado si caben; si no, uno debajo del otro.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: 16) {
                    balance
                    Spacer(minLength: 8)
                    details(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 12 * scale) {
                    balance
                    details(alignment: .leading)
                }
            }
            Label(statusText, systemImage: statusIcon)
                .appFont(.subheadline, weight: .semibold)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.18), in: Capsule())
            if !transfers.isEmpty || debt.autoPayment?.account != nil {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(transfers) { plan in
                        promo(plan)
                    }
                    if let plan = debt.autoPayment, let account = plan.account {
                        note(t.autoPay + ": " + t.autoPaySummary(amount: plan.amount, account: account.name, next: plan.nextPayDate),
                             icon: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(21 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: tint.solid(scheme).opacity(0.16), radius: 12, y: 8)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }

    private var balance: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(t.remainingBalance)
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.white.opacity(0.8))
            Text(t.money(debt.totalOwed))
                .font(.system(size: 36 * scale, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private func details(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            if estimate.payment > 0 {
                Text(t.perMonth(estimate.payment))
                    .appFont(.body, weight: .semibold)
                    .monospacedDigit()
            }
            if case .months(let months) = estimate.status {
                Text(t.payoffBy(LoanMath.endDate(start: Date(), months: months)))
                    .appFont(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var transfers: [InstallmentPlan] {
        debt.installmentPlans.filter { $0.kind == .balanceTransfer && $0.totalAmount > 0 }
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

    @ViewBuilder
    private func promo(_ plan: InstallmentPlan) -> some View {
        if plan.transferEstimate().isExpired {
            note(t.promoExpired + " · " + t.date(plan.promoEndDate), icon: "exclamationmark.triangle.fill")
        } else {
            note(t.promoEnds(plan.promoEndDate) + " · " + t.monthsLeftShort(plan.remainingMonths()), icon: "calendar")
        }
    }

    private func note(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .appFont(.subheadline)
            .foregroundStyle(.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
    }
}
