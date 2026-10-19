import SwiftUI
import SwiftData

struct DebtsListView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var debts: [Debt]
    @AppStorage("debts.excludedCollapsed") private var excludedCollapsed = false
    @State private var newKind: DebtKind?

    private var totalDebt: Double {
        debts.countedTotal
    }

    private var excluded: [Debt] {
        debts.filter(\.excludedFromTotal)
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

                    Section {
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
