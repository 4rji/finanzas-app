import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        debts.countedTotal
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(t.weekdayDate(Date()))
                            .appFont(.subheadline, weight: .medium)
                            .foregroundStyle(.secondary)
                        Text(t.financialOverview)
                            .font(.system(size: 28 * scale, weight: .bold, design: .rounded))
                            .tracking(-0.8)
                    }
                    Spacer(minLength: 0)
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
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
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
        .onChange(of: visibleSections, initial: true) {
            if selected == nil || !visibleSections.contains(where: { $0 == selected }) {
                selected = visibleSections.first
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
            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) {
                layout = layout == .carousel ? .grid : .carousel
            }
        } label: {
            Image(systemName: layout == .carousel ? "square.grid.2x2" : "rectangle.stack")
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundStyle(ThemeTint.mint.solid(scheme))
                .frame(width: 44 * scale, height: 44 * scale)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(scheme == .dark ? Color.white.opacity(0.08) : .white)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
                }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(layout == .carousel ? t.showAsGrid : t.showAsCarousel)
        .help(layout == .carousel ? t.showAsGrid : t.showAsCarousel)
    }

    /// Todas las tarjetas a la vista, dos por fila y más chicas, para no tener que bajar.
    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(visibleSections, id: \.self) { section in
                card(for: section, compact: true)
                    .frame(height: 196 * scale)
            }
        }
    }

    /// Las pestañas quedan siempre a la vista. La siguiente tarjeta se asoma y los controles
    /// permiten recorrer el carrusel también con ratón y teclado.
    private var carousel: some View {
        VStack(alignment: .leading, spacing: 20) {
            if visibleSections.count > 1 {
                sectionTabs
            }

            GeometryReader { geometry in
                let width = geometry.size.width
                let cardWidth = visibleSections.count == 1 ? width : width * (width > 600 ? 0.78 : 0.91)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(visibleSections, id: \.self) { section in
                            card(for: section, compact: false)
                                .frame(width: cardWidth, height: 248 * scale)
                                .id(section)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, 8)
                }
                .contentMargins(.trailing, width - cardWidth, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selected, anchor: .leading)
                .scrollIndicators(.hidden)
            }
            .frame(height: 248 * scale + 16)

            if visibleSections.count > 1 {
                carouselControls
            }
        }
    }

    private var sectionTabs: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                ForEach(visibleSections, id: \.self) { section in
                    sectionTab(section)
                        .frame(minWidth: 62 * scale)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(visibleSections, id: \.self) { section in
                    sectionTab(section)
                }
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(scheme == .dark ? Color(hex: 0x17251F) : .white.opacity(0.9))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: .black.opacity(scheme == .dark ? 0.12 : 0.035), radius: 16, y: 6)
    }

    private func sectionTab(_ section: HomeSection) -> some View {
        SectionChip(
            title: t.homeSectionTabName(section),
            systemImage: section.systemImage,
            tint: section.tint,
            isSelected: section == currentSection
        ) {
            select(section)
        }
    }

    private var carouselControls: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(visibleSections, id: \.self) { section in
                    Capsule()
                        .fill(section == currentSection ? section.tint.solid(scheme) : Color.primary.opacity(0.15))
                        .frame(width: section == currentSection ? 24 : 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            Text("\(currentIndex + 1) / \(visibleSections.count)")
                .appFont(.subheadline, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel(t.carouselPosition(currentIndex + 1, total: visibleSections.count))
            Spacer()
            carouselArrow("chevron.left", label: t.previousSection, disabled: currentIndex == 0) {
                moveSelection(by: -1)
            }
            carouselArrow("chevron.right", label: t.nextSection, disabled: currentIndex == visibleSections.count - 1) {
                moveSelection(by: 1)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: currentSection)
    }

    private var currentIndex: Int {
        currentSection.flatMap { visibleSections.firstIndex(of: $0) } ?? 0
    }

    private func select(_ section: HomeSection) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) {
            selected = section
        }
    }

    private func moveSelection(by offset: Int) {
        let index = currentIndex + offset
        guard visibleSections.indices.contains(index) else { return }
        select(visibleSections[index])
    }

    private func carouselArrow(_ symbol: String, label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13 * scale, weight: .bold))
                .foregroundStyle(disabled ? Color.secondary.opacity(0.4) : Color.primary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(scheme == .dark ? Color.white.opacity(0.07) : .white)
                }
        }
        .buttonStyle(PressableStyle())
        .disabled(disabled)
        .accessibilityLabel(label)
        .help(label)
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
            DashboardCard(
                title: t.accounts,
                systemImage: HomeSection.accounts.systemImage,
                amount: accounts.totalBalance,
                caption: t.totalBalance,
                subtitle: accountsSubtitle,
                tint: HomeSection.accounts.tint,
                compact: compact,
                history: BalanceHistory.points(
                    current: accounts.totalBalance,
                    changes: BalanceHistory.checkingChanges(movements)
                )
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
                DashboardCard(
                    title: t.investments,
                    systemImage: section.systemImage,
                    amount: investments.totalBalance,
                    caption: t.totalValue,
                    subtitle: investmentsSubtitle,
                    tint: section.tint,
                    compact: compact
                )
            }
            .buttonStyle(PressableStyle())
        case .debts:
            NavigationLink {
                DebtsListView()
            } label: {
                DashboardCard(
                    title: t.debts,
                    systemImage: section.systemImage,
                    amount: totalDebt,
                    caption: t.totalDebt,
                    subtitle: debtsSubtitle,
                    tint: section.tint,
                    compact: compact
                )
            }
            .buttonStyle(PressableStyle())
        case .assets:
            NavigationLink {
                AssetsView()
            } label: {
                DashboardCard(
                    title: t.assets,
                    systemImage: section.systemImage,
                    amount: assets.reduce(0) { $0 + $1.value },
                    caption: t.totalValue,
                    subtitle: assetsSubtitle,
                    tint: section.tint,
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

/// Una misma jerarquía visual para todas las categorías. Solo las cuentas muestran una gráfica,
/// construida con su historial real; las otras categorías llevan un símbolo decorativo.
private struct DashboardCard: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    let title: String
    let systemImage: String
    let amount: Double
    let caption: String
    let subtitle: String
    let tint: ThemeTint
    let compact: Bool
    var history: [Double]? = nil

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
        let icon: CGFloat = compact ? 28 : 38

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: compact ? 8 : 10) {
                Image(systemName: systemImage)
                    .font(.system(size: icon * 0.47 * scale, weight: .semibold, design: .rounded))
                    .frame(width: icon * scale, height: icon * scale)
                    .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: icon * 0.32 * scale, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: icon * 0.32 * scale, style: .continuous)
                            .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                    }
                Text(title)
                    .appFont(compact ? .subheadline : .body, weight: .semibold)
                    .lineLimit(compact ? 2 : 1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                if !compact {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .frame(width: 30 * scale, height: 30 * scale)
                        .background(.white.opacity(0.12), in: Circle())
                }
            }
            Spacer(minLength: 12 * scale)
            VStack(alignment: .leading, spacing: 4 * scale) {
                Text(caption)
                    .appFont(.subheadline, weight: .medium)
                    .foregroundStyle(.white.opacity(0.8))
                Text(t.money(amount))
                    .font(.system(size: (compact ? 28 : 42) * scale, weight: .bold, design: .rounded))
                    .tracking(-1)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(subtitle)
                .appFont(.subheadline, weight: .medium)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(compact ? 1 : 2)
                .padding(.top, 7 * scale)
            Spacer(minLength: compact ? 14 * scale : 18 * scale)
            if let history {
                Sparkline(values: history, color: .white.opacity(0.65))
                    .frame(height: (compact ? 20 : 30) * scale)
                    .accessibilityHidden(true)
            } else {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 32 * scale, height: 3)
                    .frame(height: (compact ? 20 : 30) * scale, alignment: .bottomLeading)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(.white)
        .padding((compact ? 16 : 24) * scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .stroke(.white.opacity(0.06), lineWidth: compact ? 28 : 48)
                    .frame(width: compact ? 150 : 260, height: compact ? 150 : 260)
                    .offset(x: compact ? 65 : 90, y: compact ? 70 : 130)
                if history == nil {
                    Image(systemName: systemImage)
                        .font(.system(size: (compact ? 72 : 128) * scale, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.06))
                        .rotationEffect(.degrees(-15))
                        .offset(x: 12, y: 14)
                        .accessibilityHidden(true)
                }
            }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 1
            )
        )
        .contentShape(shape)
    }
}

/// Pestaña con superficie propia, icono y nombre; la elegida tiene un relleno de alto contraste.
private struct SectionChip: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let systemImage: String
    let tint: ThemeTint
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        Button(action: action) {
            VStack(spacing: 7 * scale) {
                Image(systemName: systemImage)
                    .font(.system(size: 19 * scale, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : tint.solid(scheme))
                    .frame(height: 23 * scale)
                Text(title)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12 * scale)
            .background {
                if isSelected {
                    shape.fill(LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    shape.fill(Color.primary.opacity(scheme == .dark ? 0.04 : 0.025))
                }
            }
            .overlay(shape.strokeBorder(isSelected ? .white.opacity(0.15) : Color.primary.opacity(0.05), lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Tarjeta chica de vidrio que solo lleva a otra pantalla.
private struct LinkCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    @Environment(\.l10n) private var t
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) {
                illustration
                details
                Spacer(minLength: 12)
                arrow
            }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    illustration
                    Spacer()
                    arrow
                }
                details
            }
        }
        .padding(22 * scale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            shape.fill(scheme == .dark ? Color(hex: 0x1A2D28) : Color.white)
        }
        .overlay {
            shape.strokeBorder(ThemeTint.mint.solid(scheme).opacity(0.2), lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(ThemeTint.mint.solid(scheme))
                .frame(width: 4, height: 36 * scale)
        }
        .contentShape(shape)
    }

    private var illustration: some View {
        Image(systemName: systemImage)
            .font(.system(size: 26 * scale, weight: .medium))
            .foregroundStyle(ThemeTint.mint.solid(scheme))
            .frame(width: 62 * scale, height: 62 * scale)
            .background(ThemeTint.mint.solid(scheme).opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t.timeToPayoff)
                .font(.system(size: 10 * scale, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(ThemeTint.mint.solid(scheme))
            Text(title)
                .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(scheme == .dark ? Color.white : Color(hex: 0x172B24))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .appFont(.subheadline)
                .foregroundStyle(scheme == .dark ? Color.white.opacity(0.68) : Color(hex: 0x5B6B63))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var arrow: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 15 * scale, weight: .semibold))
            .foregroundStyle(ThemeTint.mint.solid(scheme))
            .frame(width: 40 * scale, height: 40 * scale)
            .background(ThemeTint.mint.solid(scheme).opacity(0.1), in: Circle())
            .accessibilityHidden(true)
    }
}
