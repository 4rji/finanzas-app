import SwiftUI

struct AmortizationTableView: View {
    @Environment(\.l10n) private var t
    let rows: [Amortization.Row]

    var body: some View {
        content
            .navigationTitle(t.amortizationTable)
    }

    #if os(macOS)
    private var content: some View {
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
    }

    private func amount(_ value: Double) -> some View {
        Text(t.money(value))
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    #else
    /// En iPhone no caben las columnas: una fila por mes con el desglose abajo.
    private var content: some View {
        List(rows) { row in
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("\(row.id). " + t.monthYear(row.date))
                        .appFont(.body, weight: .medium)
                    Spacer()
                    Text(t.money(row.payment))
                        .monospacedDigit()
                }
                Text([
                    t.interest + " " + t.money(row.interest),
                    t.principal + " " + t.money(row.principal),
                    t.balance + " " + t.money(row.balance),
                ].joined(separator: " · "))
                    .appFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
    #endif
}
