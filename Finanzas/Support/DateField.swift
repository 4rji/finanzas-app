import SwiftUI

/// Fila de fecha. Al tocarla se elige primero el día, luego el mes y al final el año.
struct DateField: View {
    @Environment(\.l10n) private var t
    let title: String
    @Binding var date: Date

    @State private var picking = false

    var body: some View {
        LabeledContent(title) {
            Button {
                picking = true
            } label: {
                Label(t.date(date), systemImage: "calendar")
                    .monospacedDigit()
            }
            .popover(isPresented: $picking, arrowEdge: .bottom) {
                StepDatePicker(date: $date) { picking = false }
            }
        }
    }
}

private enum DateStep: CaseIterable, Identifiable {
    case day, month, year

    var id: Self { self }
}

/// Selector por pasos: cuadrícula de 31 días, luego 12 meses, luego 10 años desde el actual.
private struct StepDatePicker: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale

    @Binding var date: Date
    let onDone: () -> Void

    @State private var step: DateStep = .day
    @State private var day: Int
    @State private var month: Int
    @State private var year: Int

    private let years: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array(current..<current + 10)
    }()

    init(date: Binding<Date>, onDone: @escaping () -> Void) {
        _date = date
        self.onDone = onDone
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date.wrappedValue)
        _day = State(initialValue: parts.day ?? 1)
        _month = State(initialValue: parts.month ?? 1)
        _year = State(initialValue: parts.year ?? 2000)
    }

    private var spacing: CGFloat { 6 * scale }
    private var cellHeight: CGFloat { 34 * scale }

    var body: some View {
        VStack(spacing: 12 * scale) {
            header

            Group {
                switch step {
                case .day:
                    grid(columns: 7, items: Array(1...31), selected: day, label: { "\($0)" }) {
                        day = $0
                        commit()
                        step = .month
                    }
                case .month:
                    grid(columns: 4, items: Array(1...12), selected: month, label: monthName) {
                        month = $0
                        commit()
                        step = .year
                    }
                case .year:
                    grid(columns: 5, items: years, selected: year, label: { "\($0)" }) {
                        year = $0
                        commit()
                        onDone()
                    }
                }
            }
            // Mismo alto en los tres pasos para que el popover no brinque.
            .frame(height: 5 * cellHeight + 4 * spacing)
        }
        .padding(14 * scale)
        .frame(width: 300 * scale)
        .animation(.easeInOut(duration: 0.15), value: step)
    }

    private var header: some View {
        HStack(spacing: spacing) {
            ForEach(DateStep.allCases) { item in
                Button {
                    step = item
                } label: {
                    VStack(spacing: 1) {
                        Text(title(item))
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(value(item))
                            .appFont(.headline)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6 * scale)
                    .background(
                        step == item ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8 * scale)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8 * scale))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func grid(
        columns: Int,
        items: [Int],
        selected: Int,
        label: @escaping (Int) -> String,
        onPick: @escaping (Int) -> Void
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(items, id: \.self) { item in
                DateCell(text: label(item), selected: item == selected, height: cellHeight) {
                    onPick(item)
                }
            }
        }
    }

    private func title(_ item: DateStep) -> String {
        switch item {
        case .day: return t.dayTitle
        case .month: return t.monthTitle
        case .year: return t.yearTitle
        }
    }

    private func value(_ item: DateStep) -> String {
        switch item {
        case .day: return "\(day)"
        case .month: return monthName(month)
        case .year: return "\(year)"
        }
    }

    private func monthName(_ month: Int) -> String {
        t.shortMonthNames[month - 1]
    }

    /// Arma la fecha; si el día no existe en ese mes (ej. 31 de febrero) usa el último día del mes.
    private func commit() {
        let calendar = Calendar.current
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count,
              let newDate = calendar.date(from: DateComponents(year: year, month: month, day: min(day, daysInMonth)))
        else { return }
        date = newDate
    }
}

private struct DateCell: View {
    let text: String
    let selected: Bool
    let height: CGFloat
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(text)
                .appFont(.body, weight: selected ? .semibold : .regular)
                .monospacedDigit()
                .foregroundStyle(selected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var background: Color {
        if selected { return .accentColor }
        return Color.secondary.opacity(hovering ? 0.22 : 0.1)
    }
}
