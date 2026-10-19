import SwiftUI
import SwiftData

struct DebtsListView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var debts: [Debt]
    @AppStorage("debts.excludedCollapsed") private var excludedCollapsed = false
    @Query(sort: \DebtGroup.createdAt) private var groups: [DebtGroup]
    @State private var newKind: DebtKind?
    @State private var addingGroup = false
    @State private var editingGroup: DebtGroup?

    private var totalDebt: Double {
        debts.countedTotal
    }

    private var excluded: [Debt] {
        debts.filter(\.excludedFromTotal)
    }

    /// Total de cada categoría con deudas que se suman, en el orden de `DebtKind`.
    private var categoryTotals: [CategoryTotal] {
        DebtKind.allCases.compactMap { kind in
            let items = debts.filter { $0.kind == kind && !$0.excludedFromTotal }
            return items.isEmpty ? nil : CategoryTotal(kind: kind, total: items.countedTotal, count: items.count)
        }
    }

    var body: some View {
        Group {
            if debts.isEmpty {
                ContentUnavailableView {
                    Label(t.noDebtsTitle, systemImage: "tray")
                } description: {
                    Text(t.noDebtsMessage)
                } actions: {
                    Menu(t.add) { addMenuItems }
                        .fixedSize()
                        .prominentButton()
                }
            } else {
                ThemedForm {
                    Section {
                        ForEach(categoryTotals) { item in
                            CategoryTotalRow(item: item, share: totalDebt > 0 ? item.total / totalDebt : 0)
                        }
                        LabeledContent(t.totalDebt) {
                            Text(t.money(totalDebt))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        if let usage = debts.creditUsage {
                            LabeledContent(t.creditUsed) {
                                HStack(spacing: 6) {
                                    Text(t.amountOf(usage.used, usage.limit))
                                        .foregroundStyle(.secondary)
                                    UsageText(fraction: usage.used / usage.limit)
                                }
                            }
                        }
                    } header: {
                        Text(t.byCategory)
                            .sectionTitle()
                    }

                    Section {
                        ForEach(groups) { group in
                            Button {
                                editingGroup = group
                            } label: {
                                DebtGroupRow(group: group)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(t.edit) { editingGroup = group }
                                Button(t.delete, role: .destructive) { delete(group) }
                            }
                        }
                        Button {
                            addingGroup = true
                        } label: {
                            Label(t.addCustomTotal, systemImage: "plus")
                        }
                    } header: {
                        Text(t.customTotals)
                            .sectionTitle()
                    } footer: {
                        Text(t.customTotalsFooter)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(DebtKind.allCases) { kind in
                        let items = debts.filter { $0.kind == kind && !$0.excludedFromTotal }
                        if !items.isEmpty {
                            Section {
                                ForEach(items) { debtLink($0) }
                            } header: {
                                Text(t.kindPlural(kind))
                                    .sectionTitle()
                            }
                        }
                    }

                    if !excluded.isEmpty {
                        Section {
                            if !excludedCollapsed {
                                ForEach(excluded) { debtLink($0) }
                            }
                        } header: {
                            Button {
                                withAnimation { excludedCollapsed.toggle() }
                            } label: {
                                HStack {
                                    Text(t.excludedFromTotal + " · \(excluded.count)")
                                        .sectionTitle()
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(excludedCollapsed ? -90 : 0))
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } footer: {
                            if !excludedCollapsed {
                                Text(t.excludedFromTotalFooter)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TabHeader(caption: t.totalDebt, amount: totalDebt) {
                if !debts.isEmpty {
                    NavigationLink {
                        PayoffView()
                            .backButton(t.debts)
                    } label: {
                        Label(t.timeToPayoff, systemImage: "calendar.badge.clock")
                    }
                    .glassButton()
                }
            } trailing: {
                Menu {
                    addMenuItems
                } label: {
                    Label(t.add, systemImage: "plus")
                }
                .menuStyle(.button)
                .prominentButton()
                .fixedSize()
            }
        }
        .screenBackground()
        .navigationTitle(t.debts)
        .hideAmountsToolbar()
        .sheet(item: $newKind) { kind in
            DebtFormView(kind: kind)
        }
        .sheet(isPresented: $addingGroup) {
            DebtGroupFormView()
        }
        .sheet(item: $editingGroup) { group in
            DebtGroupFormView(group: group)
        }
    }

    @ViewBuilder
    private var addMenuItems: some View {
        ForEach(DebtKind.allCases) { kind in
            Button {
                newKind = kind
            } label: {
                Label(t.kindName(kind), systemImage: kind.systemImage)
            }
        }
    }

    private func debtLink(_ debt: Debt) -> some View {
        NavigationLink {
            DebtDetailView(debt: debt)
                .backButton(t.debts)
        } label: {
            DebtRow(debt: debt)
        }
        .contextMenu {
            Button {
                toggleExcluded(debt)
            } label: {
                Label(excludeLabel(debt), systemImage: excludeImage(debt))
            }
            Button(t.delete, role: .destructive) {
                delete(debt)
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleExcluded(debt)
            } label: {
                Label(excludeLabel(debt), systemImage: excludeImage(debt))
            }
            .tint(.gray)
        }
    }

    private func excludeLabel(_ debt: Debt) -> String {
        debt.excludedFromTotal ? t.includeInTotal : t.excludeFromTotal
    }

    private func excludeImage(_ debt: Debt) -> String {
        debt.excludedFromTotal ? "plus.circle" : "minus.circle"
    }

    private func toggleExcluded(_ debt: Debt) {
        withAnimation { debt.excludedFromTotal.toggle() }
        try? context.save()
    }

    private func delete(_ debt: Debt) {
        context.delete(debt)
        try? context.save()
    }

    private func delete(_ group: DebtGroup) {
        context.delete(group)
        try? context.save()
    }
}

private struct CategoryTotal: Identifiable {
    let kind: DebtKind
    let total: Double
    let count: Int

    var id: DebtKind { kind }
}

/// Total de una categoría, con la parte de la deuda total que representa.
private struct CategoryTotalRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    let item: CategoryTotal
    let share: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconTile(systemImage: item.kind.systemImage, tint: item.kind.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.kindPlural(item.kind))
                        .appFont(.body, weight: .semibold)
                    Text(t.debtCount(item.count) + " · " + t.percent((share * 100).rounded()))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(t.money(item.total))
                    .appFont(.title3, weight: .bold)
                    .monospacedDigit()
            }
            ProgressView(value: min(max(share, 0), 1))
                .tint(item.kind.tint.solid(scheme))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
    }
}

/// Total personalizado con las deudas que suma.
private struct DebtGroupRow: View {
    @Environment(\.l10n) private var t
    let group: DebtGroup

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemImage: "square.stack.3d.up", tint: .mint)
            VStack(alignment: .leading, spacing: 1) {
                Text(group.name)
                    .appFont(.body, weight: .semibold)
                Text(names)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(t.money(group.total))
                .appFont(.title3, weight: .bold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var names: String {
        let names = group.sortedDebts.map(\.name)
        return names.isEmpty ? t.noDebtsChosen : names.joined(separator: ", ")
    }
}

private struct DebtRow: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    var body: some View {
        HStack(spacing: 14) {
            CardChip(systemImage: debt.kind.systemImage, tint: debt.kind.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(debt.name)
                    .appFont(.body, weight: .semibold)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(t.money(debt.totalOwed))
                .appFont(.title3, weight: .bold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        switch debt.kind {
        case .creditCard:
            let due = t.dueShort + " " + t.shortDate(debt.nextDueDate)
            guard let usage = debt.creditUsage else { return due }
            return due + " · " + t.usageUsed(usage)
        case .mortgage, .autoLoan, .studentLoan:
            return [
                t.percent(debt.interestRate),
                t.perMonth(debt.monthlyPayment),
                t.interestShort(debt.amortization.interestThisMonth),
            ].joined(separator: " · ")
        }
    }
}
