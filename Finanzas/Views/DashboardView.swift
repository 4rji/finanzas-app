import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.textScale) private var scale
    @AppStorage(HomeSection.accounts.storageKey) private var showAccounts = true
    @AppStorage(HomeSection.investments.storageKey) private var showInvestments = true
    @AppStorage(HomeSection.debts.storageKey) private var showDebts = true
    @AppStorage(HomeSection.assets.storageKey) private var showAssets = true
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
            VStack(alignment: .leading, spacing: 18) {
                Text(t.weekdayDate(Date()))
                    .sectionTitle()

                if showAccounts {
                    NavigationLink {
                        AccountsView()
                    } label: {
                        HeroCard(
                            title: t.accounts,
                            systemImage: AccountKind.checking.systemImage,
                            amount: accounts.totalBalance,
                            subtitle: accountsSubtitle,
                            tint: .mint
                        )
                    }
                    .buttonStyle(PressableStyle())
                }

                // En Mac caben dos tarjetas por fila; en iPhone, una.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280 * scale), spacing: 16)], spacing: 16) {
                    if showInvestments {
                        NavigationLink {
                            InvestmentsView()
                        } label: {
                            CategoryCard(
                                title: t.investments,
                                systemImage: AccountKind.investment.systemImage,
                                amount: investments.totalBalance,
                                subtitle: investmentsSubtitle,
                                tint: .teal,
                                seed: 0
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }

                    if showDebts {
                        NavigationLink {
                            DebtsListView()
                        } label: {
                            CategoryCard(
                                title: t.debts,
                                systemImage: "creditcard",
                                amount: totalDebt,
                                subtitle: debtsSubtitle,
                                tint: .peach,
                                seed: 1
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }

                    if showAssets {
                        NavigationLink {
                            AssetsView()
                        } label: {
                            CategoryCard(
                                title: t.assets,
                                systemImage: "tag",
                                amount: assets.reduce(0) { $0 + $1.value },
                                subtitle: assetsSubtitle,
                                tint: .sand,
                                seed: 2
                            )
                        }
                        .buttonStyle(PressableStyle())
                    }
                }

                if showDebts && !debts.isEmpty {
                    NavigationLink {
                        PayoffView()
                    } label: {
                        LinkCard(title: t.payoffQuestion, subtitle: t.payoffHint, systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(PressableStyle())
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
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle(t.appName)
        .hideAmountsToolbar()
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
        let goalCount = investments.filter { $0.kind == .goal }.count
        let investmentCount = investments.count - goalCount
        let name = investments.count == 1
            ? first.name
            : [
                investmentCount > 0 ? t.investmentCount(investmentCount) : nil,
                goalCount > 0 ? t.goalCount(goalCount) : nil,
            ].compactMap { $0 }.joined(separator: " · ")
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

/// Tarjeta grande de color, como una tarjeta de banco, para el saldo de las cuentas.
private struct HeroCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let amount: Double
    let subtitle: String
    let tint: ThemeTint

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        VStack(alignment: .leading, spacing: 14 * scale) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                    .frame(width: 34 * scale, height: 34 * scale)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 11 * scale, style: .continuous))
                Text(title)
                    .appFont(.subheadline, weight: .bold)
                    .textCase(.uppercase)
                    .tracking(1.4)
                Spacer()
                Image(systemName: "chevron.right")
                    .appFont(.headline)
                    .opacity(0.7)
            }
            Spacer(minLength: 0)
            Text(t.money(amount))
                .font(.system(size: 44 * scale, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subtitle)
                .appFont(.body, weight: .medium)
                .opacity(0.85)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(22 * scale)
        .frame(maxWidth: .infinity, minHeight: 190 * scale, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
            }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        )
        .shadow(color: tint.solid(scheme).opacity(scheme == .dark ? 0.3 : 0.35), radius: 24, y: 12)
        .contentShape(shape)
    }
}

/// Tarjeta de vidrio con el monto en el color de la categoría y una ola de adorno abajo.
private struct CategoryCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let amount: Double
    let subtitle: String
    let tint: ThemeTint
    let seed: Int

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        VStack(alignment: .leading, spacing: 10 * scale) {
            HStack(spacing: 10) {
                IconTile(systemImage: systemImage, tint: tint)
                Text(title)
                    .appFont(.subheadline, weight: .bold)
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .appFont(.headline)
                    .foregroundStyle(.tertiary)
            }
            Text(t.money(amount))
                .font(.system(size: 30 * scale, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint.solid(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subtitle)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(18 * scale)
        .padding(.bottom, 26 * scale)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(alignment: .bottom) {
            WaveDecoration(tint: tint, seed: seed)
                .frame(height: 46 * scale)
        }
        .clipShape(shape)
        .glassCard(cornerRadius: 24, tint: tint.solid(scheme).opacity(0.08))
        .contentShape(shape)
    }
}

/// Tarjeta chica de vidrio que solo lleva a otra pantalla.
private struct LinkCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: systemImage, tint: .mint, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(.body, weight: .semibold)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .appFont(.headline)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .glassCard(cornerRadius: 22)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
