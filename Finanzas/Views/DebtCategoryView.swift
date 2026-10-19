import SwiftUI
import SwiftData
import Charts

/// Solo las deudas de una categoría, con su resumen y una gráfica de cómo ha subido o bajado el total.
struct DebtCategoryView: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    @Query(sort: \Debt.createdAt) private var allDebts: [Debt]
    @AppStorage(HistoryRange.storageKey) private var range: HistoryRange = .sixMonths
    let kind: DebtKind

    private var debts: [Debt] { allDebts.filter { $0.kind == kind } }
    private var counted: [Debt] { debts.filter { !$0.excludedFromTotal } }
    private var excluded: [Debt] { debts.filter(\.excludedFromTotal) }
    private var total: Double { counted.countedTotal }

    private var surface: Color {
        scheme == .dark ? Color(hex: 0x1A261F) : .white
    }

    var body: some View {
        let now = Date()
        let events = BalanceHistory.debtEvents(for: counted, asOf: now)
        let points = BalanceHistory.series(current: total, events: events, from: startDate(events, now: now), to: now)

        Group {
            if debts.isEmpty {
                ContentUnavailableView(t.noDebtsTitle, systemImage: kind.systemImage, description: Text(t.noDebtsMessage))
            } else {
                GeometryReader { geometry in
                    let compact = geometry.size.width < 620 * scale
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16 * scale) {
                            hero(points)
                            chartCard(points)
                            if !counted.isEmpty {
                                debtSection(counted, title: t.debts)
                            }
                            if !excluded.isEmpty {
                                debtSection(excluded, title: t.excludedFromTotal)
                            }
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
        .navigationTitle(t.kindPlural(kind))
        .hideAmountsToolbar()
    }

    /// Inicio del periodo. En "Todo", un día antes del primer cambio para que se vea completo.
    private func startDate(_ events: [BalanceHistory.DebtEvent], now: Date) -> Date {
        let calendar = Calendar.current
        if let months = range.months {
            return calendar.date(byAdding: .month, value: -months, to: now) ?? now
        }
        let earliest = (counted.map(\.createdAt) + events.prefix(1).map(\.date)).min() ?? now
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        return min(earliest.addingTimeInterval(-86_400), monthAgo)
    }

    private func hero(_ points: [BalanceHistory.Point]) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        let change = total - (points.first?.value ?? total)
        let monthly = counted.reduce(0) { $0 + $1.payoffEstimate().payment }
        let allTotal = allDebts.countedTotal

        return VStack(alignment: .leading, spacing: 14 * scale) {
            HStack(spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 15 * scale, weight: .semibold))
                    .frame(width: 34 * scale, height: 34 * scale)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
                Text(t.debtCount(counted.count))
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.white.opacity(0.85))
            }
            VStack(alignment: .leading, spacing: 4 * scale) {
                Text(t.totalDebt)
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.white.opacity(0.8))
                Text(t.money(total))
                    .font(.system(size: 36 * scale, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Label(t.debtChange(change, range: range), systemImage: changeIcon(change))
                .appFont(.subheadline, weight: .semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.16), in: Capsule())
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 1)
            HStack(alignment: .top, spacing: 16) {
                metric(t.monthlyPayments, value: t.perMonth(monthly))
                if kind == .creditCard, let usage = counted.creditUsage {
                    metric(t.creditUsed, value: t.usage(usage.used / usage.limit))
                } else {
                    metric(t.ofTotalDebt, value: t.usage(allTotal > 0 ? total / allTotal : 0))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: kind.tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 1))
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

    private func changeIcon(_ change: Double) -> String {
        if change > 0.005 { return "arrow.up.right" }
        if change < -0.005 { return "arrow.down.right" }
        return "equal"
    }

    private func chartCard(_ points: [BalanceHistory.Point]) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let color = kind.tint.solid(scheme)
        let values = points.map(\.value)
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        // Margen arriba y abajo para que la línea no quede pegada a las orillas.
        let pad = max((high - low) * 0.2, max(abs(high) * 0.05, 1))
        let domain = (low >= 0 ? max(low - pad, 0) : low - pad)...(high + pad)
        let dates = (points.first?.date ?? Date())...(points.last?.date ?? Date())
        let dateFormat: Date.FormatStyle = range == .all
            ? .dateTime.month(.abbreviated).year(.twoDigits)
            : .dateTime.month(.abbreviated)

        return VStack(alignment: .leading, spacing: 14 * scale) {
            Text(t.history)
                .font(.system(size: 17 * scale, weight: .bold, design: .rounded))
                .accessibilityAddTraits(.isHeader)
            Picker(t.history, selection: $range) {
                ForEach(HistoryRange.allCases) { option in
                    Text(t.historyRangeName(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Chart(points) { point in
                AreaMark(
                    x: .value(t.dateLabel, point.date),
                    yStart: .value(t.totalDebt, domain.lowerBound),
                    yEnd: .value(t.totalDebt, point.value)
                )
                .interpolationMethod(.stepEnd)
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.28), color.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                LineMark(
                    x: .value(t.dateLabel, point.date),
                    y: .value(t.totalDebt, point.value)
                )
                .interpolationMethod(.stepEnd)
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            .chartYScale(domain: domain)
            .chartXScale(domain: dates)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(t.moneyCompact(amount))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.primary.opacity(0.05))
                    AxisValueLabel(format: dateFormat)
                }
            }
            .frame(height: 190 * scale)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(t.history)
            .accessibilityValue(t.debtChange(total - (points.first?.value ?? total), range: range))
            Text(t.debtHistoryFooter)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surface, in: shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private func debtSection(_ items: [Debt], title: String) -> some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            Text(title)
                .sectionTitle()
                .padding(.horizontal, 4)
            ForEach(items) { debt in
                let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
                NavigationLink {
                    DebtDetailView(debt: debt)
                        .backButton(t.kindPlural(kind))
                } label: {
                    HStack(spacing: 10) {
                        DebtRow(debt: debt)
                        Image(systemName: "chevron.right")
                            .appFont(.subheadline, weight: .semibold)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(surface, in: shape)
                    .overlay(shape.strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                    .contentShape(shape)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}
