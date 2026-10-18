import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var debts: [Debt]
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var incomes: [RecurringIncome]
    @Query private var movements: [Movement]

    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.totalOwed }
    }

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    AccountsView()
                } label: {
                    SummaryCard(
                        title: t.accounts,
                        systemImage: "building.columns",
                        amount: totalBalance,
                        subtitle: accountsSubtitle
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    DebtsListView()
                } label: {
                    SummaryCard(
                        title: t.debts,
                        systemImage: "creditcard",
                        amount: totalDebt,
                        subtitle: debtsSubtitle
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
                #if os(macOS)
                SettingsLink {
                    Label(t.settings, systemImage: "gearshape")
                }
                #else
                NavigationLink {
                    SettingsView()
                } label: {
                    Label(t.settings, systemImage: "gearshape")
                }
                #endif
            }
        }
        // Suma los depósitos recurrentes que ya tocan al abrir la app, al volver a ella y cuando
        // cambian los movimientos (por ejemplo, al llegar cambios de otro dispositivo).
        .task { RecurringDeposits.update(in: context) }
        .onChange(of: scenePhase) {
            if scenePhase == .active { RecurringDeposits.update(in: context) }
        }
        .onChange(of: movements.count) {
            RecurringDeposits.update(in: context)
        }
    }

    private var accountsSubtitle: String {
        guard let first = accounts.first else { return t.addAccountHint }
        let name = accounts.count == 1 ? first.name : t.accountCount(accounts.count)
        let monthly = incomes.monthlyIncome
        return monthly > 0 ? name + " · " + t.incomePerMonthShort(monthly) : name
    }

    private var debtsSubtitle: String {
        guard let usage = debts.creditUsage else { return t.debtCount(debts.count) }
        return t.debtCount(debts.count) + " · " + t.creditUsedShort(usage.used / usage.limit)
    }
}

private struct SummaryCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    let title: String
    let systemImage: String
    let amount: Double
    let subtitle: String

    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .appFont(.headline)
                    .foregroundStyle(.secondary)
                Text(t.money(amount))
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
}
