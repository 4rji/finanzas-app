import SwiftUI

struct AmortizationTableView: View {
    @Environment(\.l10n) private var t
    let rows: [Amortization.Row]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(rows) { row in
                        TableLine(columns: [
                            t.monthYear(row.date),
                            t.moneyWhole(row.interest),
                            t.moneyWhole(row.principal),
                            t.moneyWhole(row.balance),
                        ])
                        .background(row.id.isMultiple(of: 2) ? Color.secondary.opacity(0.07) : Color.clear)
                    }
                } header: {
                    TableLine(columns: [t.tableMonth, t.interest, t.principal, t.balance], isHeader: true)
                        .background(.bar)
                }
            }
        }
        .navigationTitle(t.amortizationTable)
    }
}

private struct TableLine: View {
    let columns: [String]
    var isHeader = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, text in
                Text(text)
                    .frame(maxWidth: .infinity, alignment: index == 0 ? .leading : .trailing)
            }
        }
        .font(isHeader ? Font.caption.weight(.semibold) : Font.callout)
        .foregroundStyle(isHeader ? Color.secondary : Color.primary)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
