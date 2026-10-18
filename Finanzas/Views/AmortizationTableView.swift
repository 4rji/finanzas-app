import SwiftUI

struct AmortizationTableView: View {
    @Environment(\.l10n) private var t
    let rows: [Amortization.Row]

    var body: some View {
        Table(rows) {
            TableColumn("#") { row in
                Text(String(row.id))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .width(56)
            TableColumn(t.tableMonth) { row in
                Text(t.monthYear(row.date))
            }
            TableColumn(t.payment) { row in
                amount(row.payment)
            }
            TableColumn(t.interest) { row in
                amount(row.interest)
            }
            TableColumn(t.principal) { row in
                amount(row.principal)
            }
            TableColumn(t.balance) { row in
                amount(row.balance)
            }
        }
        .navigationTitle(t.amortizationTable)
    }

    private func amount(_ value: Double) -> some View {
        Text(t.money(value))
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
