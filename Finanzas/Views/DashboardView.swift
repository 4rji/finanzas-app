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
    @AppStorage(HomeSection.orderKey) private var orderRaw = ""
    @AppStorage(HomeSection.selectedKey) private var selectedRaw = ""
    @AppStorage(HomeLayout.storageKey) private var layout: HomeLayout = .carousel
    @Query private var debts: [Debt]
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query private var incomes: [RecurringIncome]
    @Query private var movements: [Movement]
    @Query(sort: \Asset.createdAt) private var assets: [Asset]

    @State private var showingSettings = false
    /// Tarjeta del carrusel que está al inicio. Arranca en la última que se eligió.
    @State private var selected: HomeSection? = HomeSection(
        rawValue: UserDefaults.standard.string(forKey: HomeSection.selectedKey) ?? ""
    )

    private var accounts: [Account] { allAccounts.checking }
    private var investments: [Account] { allAccounts.investments }

    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.totalOwed }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(t.weekdayDate(Date()))
                        .sectionTitle()
                    Spacer()
                    if visibleSections.count > 1 {
                        layoutButton
                    }
                }

                if visibleSections.isEmpty {
                    ContentUnavailableView(
                        t.everythingHidden,
                        systemImage: "eye.slash",
                        description: Text(t.everythingHiddenMessage)
                    )
                } else if layout == .grid {
                    grid
                } else {
                    carousel
                }

                if showDebts && !debts.isEmpty {
                    NavigationLink {
                        PayoffView()
                    } label: {
                        LinkCard(title: t.payoffQuestion, subtitle: t.payoffHint, systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(PressableStyle())
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
                Button {
                    showingSettings = true
                } label: {
                    Label(t.settings, systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: selected) {
            if let selected { selectedRaw = selected.rawValue }
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

    /// Secciones visibles en el orden de Configuración.
    private var visibleSections: [HomeSection] {
        HomeSection.ordered(orderRaw).filter(isShown)
    }

    /// La sección elegida, o la primera si la elegida está oculta.
    private var currentSection: HomeSection? {
        if let selected, visibleSections.contains(selected) { return selected }
        return visibleSections.first
    }

    /// Cambia entre carrusel y cuadrícula; dice a cuál se va a cambiar.
    private var layoutButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                layout = layout == .carousel ? .grid : .carousel
            }
        } label: {
            Label(
                layout == .carousel ? t.showAsGrid : t.showAsCarousel,
                systemImage: layout == .carousel ? "square.grid.2x2" : "rectangle.stack"
            )
            .appFont(.subheadline, weight: .semibold)
        }
        .glassButton()
    }

    /// Todas las tarjetas a la vista, dos por fila y más chicas, para no tener que bajar.
    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(visibleSections, id: \.self) { section in
                card(for: section, compact: true)
                    .frame(height: 170 * scale)
            }
        }
    }

    /// Tarjetas que se deslizan de lado; la siguiente se asoma para que se note que hay más. Abajo,
    /// todas las secciones disponibles: al elegir una, su tarjeta queda al inicio.
    private var carousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(visibleSections, id: \.self) { section in
                        card(for: section, compact: false)
                            .frame(height: 250 * scale)
                            .containerRelativeFrame(.horizontal) { length, _ in
                                // En iPhone una tarjeta y la orilla de la siguiente; en Mac, casi dos.
                                length > 600 ? (length - 16) * 0.48 : length * 0.86
                            }
                            .id(section)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selected)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()

            if visibleSections.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(visibleSections, id: \.self) { section in
                            SectionChip(
                                title: t.homeSectionName(section),
                                systemImage: section.systemImage,
                                tint: section.tint,
                                isSelected: section == currentSection
                            ) {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    selected = section
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
        }
    }

    private func isShown(_ section: HomeSection) -> Bool {
        switch section {
        case .accounts: return showAccounts
        case .investments: return showInvestments
        case .debts: return showDebts
        case .assets: return showAssets
        }
    }

    private func accountsCard(compact: Bool) -> some View {
        NavigationLink {
            AccountsView()
        } label: {
            HeroCard(
                title: t.accounts,
                systemImage: HomeSection.accounts.systemImage,
                amount: accounts.totalBalance,
                subtitle: accountsSubtitle,
                history: BalanceHistory.points(
                    current: accounts.totalBalance,
                    changes: BalanceHistory.checkingChanges(movements)
                ),
                tint: HomeSection.accounts.tint,
                compact: compact
            )
        }
        .buttonStyle(PressableStyle())
    }

    @ViewBuilder
    private func card(for section: HomeSection, compact: Bool) -> some View {
        switch section {
        case .accounts:
            accountsCard(compact: compact)
        case .investments:
            NavigationLink {
                InvestmentsView()
            } label: {
                CategoryCard(
                    title: t.investments,
                    systemImage: section.systemImage,
                    amount: investments.totalBalance,
                    subtitle: investmentsSubtitle,
                    tint: section.tint,
                    seed: 0,
                    compact: compact
                )
            }
            .buttonStyle(PressableStyle())
        case .debts:
            NavigationLink {
                DebtsListView()
            } label: {
                CategoryCard(
                    title: t.debts,
                    systemImage: section.systemImage,
                    amount: totalDebt,
                    subtitle: debtsSubtitle,
                    tint: section.tint,
                    seed: 1,
                    compact: compact
                )
            }
            .buttonStyle(PressableStyle())
        case .assets:
            NavigationLink {
                AssetsView()
            } label: {
                CategoryCard(
                    title: t.assets,
                    systemImage: section.systemImage,
                    amount: assets.reduce(0) { $0 + $1.value },
                    subtitle: assetsSubtitle,
                    tint: section.tint,
                    seed: 2,
                    compact: compact
                )
            }
            .buttonStyle(PressableStyle())
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

/// Tarjeta grande de color, como una tarjeta de banco, para el saldo de las cuentas. Al pie va la
/// línea de cómo ha subido y bajado el saldo. `compact` es la versión chica de la cuadrícula.
private struct HeroCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let amount: Double
    let subtitle: String
    let history: [Double]
    let tint: ThemeTint
    let compact: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
        let icon: CGFloat = compact ? 28 : 34

        VStack(alignment: .leading, spacing: (compact ? 8 : 14) * scale) {
            HStack(spacing: compact ? 8 : 10) {
                Image(systemName: systemImage)
                    .font(.system(size: icon * 0.47 * scale, weight: .semibold, design: .rounded))
                    .frame(width: icon * scale, height: icon * scale)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: icon * 0.32 * scale, style: .continuous))
                Text(title)
                    .appFont(.subheadline, weight: .bold)
                    .textCase(.uppercase)
                    .tracking(compact ? 1 : 1.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if !compact {
                    Image(systemName: "chevron.right")
                        .appFont(.headline)
                        .opacity(0.7)
                }
            }
            Text(t.money(amount))
                .font(.system(size: (compact ? 26 : 44) * scale, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subtitle)
                .appFont(compact ? .subheadline : .body, weight: .medium)
                .opacity(0.85)
                .lineLimit(compact ? 1 : 2)
        }
        .foregroundStyle(.white)
        .padding((compact ? 14 : 22) * scale)
        .padding(.bottom, (compact ? 36 : 58) * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Bubbles()
                Sparkline(values: history)
                    .frame(height: (compact ? 32 : 56) * scale)
                    .padding(.bottom, (compact ? 10 : 14) * scale)
            }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        )
        .shadow(color: tint.solid(scheme).opacity(scheme == .dark ? 0.3 : 0.35), radius: compact ? 14 : 24, y: compact ? 6 : 12)
        .contentShape(shape)
    }
}

/// Tarjeta de vidrio con el monto en el color de la categoría y una ola de adorno abajo. `compact`
/// es la versión chica de la cuadrícula.
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
    let compact: Bool

    var body: some View {
        let radius: CGFloat = compact ? 22 : 24
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        VStack(alignment: .leading, spacing: (compact ? 8 : 10) * scale) {
            HStack(spacing: compact ? 8 : 10) {
                IconTile(systemImage: systemImage, tint: tint, size: compact ? 28 : 34)
                Text(title)
                    .appFont(.subheadline, weight: .bold)
                    .textCase(.uppercase)
                    .tracking(compact ? 0.8 : 1.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if !compact {
                    Image(systemName: "chevron.right")
                        .appFont(.headline)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(t.money(amount))
                .font(.system(size: (compact ? 24 : 30) * scale, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint.solid(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(subtitle)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(compact ? 1 : 2)
        }
        .padding((compact ? 14 : 18) * scale)
        .padding(.bottom, (compact ? 18 : 26) * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .bottom) {
            WaveDecoration(tint: tint, seed: seed)
                .frame(height: (compact ? 30 : 46) * scale)
        }
        .clipShape(shape)
        .glassCard(cornerRadius: radius, tint: tint.solid(scheme).opacity(0.08))
        .contentShape(shape)
    }
}

/// Píldora de una sección del carrusel; la elegida va rellena con su color.
private struct SectionChip: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let tint: ThemeTint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = tint.solid(scheme)

        Button(action: action) {
            Label(title, systemImage: systemImage)
                .appFont(.subheadline, weight: .semibold)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? Color.white : color)
                .background(isSelected ? color : color.opacity(0.14), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
