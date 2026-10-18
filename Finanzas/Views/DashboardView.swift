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
                    DebtsSummaryCard(
                        total: totalDebt,
                        count: debts.count,
                        creditUsage: debts.creditUsage.map { $0.used / $0.limit }
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 720)
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
    @Environment(\.textScale) private var scale
    let total: Double
    let count: Int
    let creditUsage: Double?

    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(t.debts, systemImage: "creditcard")
                    .appFont(.headline)
                    .foregroundStyle(.secondary)
                Text(t.money(total))
                    .font(.system(size: 36 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .appFont(.headline)
                .foregroundStyle(.tertiary)
        }
        .padding(20 * scale)
        .background(Color.cardBackground, in: shape)
        .overlay(shape.strokeBorder(Color.secondary.opacity(hovering ? 0.4 : 0.2), lineWidth: hovering ? 1 : 0.5))
        .contentShape(shape)
        .onHover { hovering = $0 }
    }

    private var subtitle: String {
        guard let creditUsage else { return t.debtCount(count) }
        return t.debtCount(count) + " · " + t.creditUsedShort(creditUsage)
    }
}
