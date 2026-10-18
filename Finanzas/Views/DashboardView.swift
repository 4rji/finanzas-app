import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.l10n) private var t
    @Query private var debts: [Debt]

    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.totalOwed }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    DebtsListView()
                } label: {
                    DebtsSummaryCard(total: totalDebt, count: debts.count)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Color.groupedBackground)
        .navigationTitle(t.appName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink {
                    Label(t.settings, systemImage: "gearshape")
                }
            }
        }
    }
}

private struct DebtsSummaryCard: View {
    @Environment(\.l10n) private var t
    let total: Double
    let count: Int

    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(t.debts, systemImage: "creditcard")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(t.money(total))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(t.debtCount(count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(Color.cardBackground, in: shape)
        .overlay(shape.strokeBorder(Color.secondary.opacity(hovering ? 0.4 : 0.2), lineWidth: hovering ? 1 : 0.5))
        .contentShape(shape)
        .onHover { hovering = $0 }
    }
}
