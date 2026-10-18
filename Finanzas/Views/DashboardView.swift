import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(HomeSection.accounts.storageKey) private var showAccounts = true
    @AppStorage(HomeSection.investments.storageKey) private var showInvestments = true
    @AppStorage(HomeSection.debts.storageKey) private var showDebts = true
    @AppStorage(HomeSection.assets.storageKey) private var showAssets = true
    @AppStorage(L10n.hidesAmountsKey) private var hidesAmounts = false
    @Query private var debts: [Debt]
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query private var incomes: [RecurringIncome]
    @Query private var movements: [Movement]
    @Query(sort: \Asset.createdAt) private var assets: [Asset]

    private var accounts: [Account] { allAccounts.checking }
    private var investments: [Account] { allAccounts.investments }

    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.totalOwed }
    }

    private var showsAnything: Bool {
        showAccounts || showInvestments || showDebts || showAssets
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showAccounts {
                    NavigationLink {
                        AccountsView()
                    } label: {
                        SummaryCard(
                            title: t.accounts,
                            systemImage: AccountKind.checking.systemImage,
                            amount: accounts.totalBalance,
                            subtitle: accountsSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                }

                if showInvestments {
                    NavigationLink {
                        InvestmentsView()
                    } label: {
                        SummaryCard(
                            title: t.investments,
                            systemImage: AccountKind.investment.systemImage,
                            amount: investments.totalBalance,
                            subtitle: investmentsSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                }

                if showDebts {
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

                    if !debts.isEmpty {
                        NavigationLink {
                            PayoffView()
                        } label: {
                            LinkCard(title: t.payoffQuestion, subtitle: t.payoffHint, systemImage: "calendar.badge.clock")
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showAssets {
                    NavigationLink {
                        AssetsView()
                    } label: {
                        SummaryCard(
                            title: t.assets,
                            systemImage: "tag",
                            amount: assets.reduce(0) { $0 + $1.value },
                            subtitle: assetsSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                }

                if !showsAnything {
                    ContentUnavailableView(
                        t.everythingHidden,
                        systemImage: "eye.slash",
                        description: Text(t.everythingHiddenMessage)
                    )
                }
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Color.groupedBackground)
        .navigationTitle(t.appName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    hidesAmounts.toggle()
                } label: {
                    Label(hidesAmounts ? t.showAmounts : t.hideAmounts, systemImage: hidesAmounts ? "eye" : "eye.slash")
                }
            }
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
        // Suma los depósitos recurrentes y aplica los pagos automáticos que ya tocan al abrir la app,
        // al volver a ella y cuando cambian los movimientos (por ejemplo, al llegar cambios de otro dispositivo).
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
        let monthly = incomes.filter { !$0.isInvestment }.monthlyIncome
        return monthly > 0 ? name + " · " + t.incomePerMonthShort(monthly) : name
    }

    private var investmentsSubtitle: String {
        guard let first = investments.first else { return t.addInvestmentHint }
        let name = investments.count == 1 ? first.name : t.investmentCount(investments.count)
        let monthly = incomes.monthlyContributions
        return monthly > 0 ? name + " · " + t.contributionsPerMonthShort(monthly) : name
    }

    private var debtsSubtitle: String {
        guard let usage = debts.creditUsage else { return t.debtCount(debts.count) }
        return t.debtCount(debts.count) + " · " + t.creditUsedShort(usage.used / usage.limit)
    }

    private var assetsSubtitle: String {
        guard let first = assets.first else { return t.addAssetHint }
        return assets.count == 1 ? first.name : t.assetCount(assets.count)
    }
}

private struct SummaryCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    let title: String
    let systemImage: String
    let amount: Double
    let subtitle: String

    var body: some View {
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
        .modifier(CardStyle(padding: 20))
    }
}

/// Tarjeta chica que solo lleva a otra pantalla.
private struct LinkCard: View {
    @Environment(\.textScale) private var scale
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .appFont(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32 * scale)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(.body, weight: .medium)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .appFont(.headline)
                .foregroundStyle(.tertiary)
        }
        .modifier(CardStyle(padding: 14))
    }
}

/// Fondo, borde y resaltado al pasar el puntero de las tarjetas de inicio.
private struct CardStyle: ViewModifier {
    @Environment(\.textScale) private var scale
    let padding: CGFloat

    @State private var hovering = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        content
            .padding(padding * scale)
            .background(Color.cardBackground, in: shape)
            .overlay(shape.strokeBorder(Color.secondary.opacity(hovering ? 0.4 : 0.2), lineWidth: hovering ? 1 : 0.5))
            .contentShape(shape)
            .onHover { hovering = $0 }
    }
}
