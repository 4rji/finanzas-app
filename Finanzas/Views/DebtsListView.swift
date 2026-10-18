import SwiftUI
import SwiftData

struct DebtsListView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var debts: [Debt]
    @State private var newKind: DebtKind?

    private var totalDebt: Double {
        debts.reduce(0) { $0 + $1.totalOwed }
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
                }
            } else {
                List {
                    Section {
                        LabeledContent(t.totalDebt) {
                            Text(t.money(totalDebt))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }

                    ForEach(DebtKind.allCases) { kind in
                        let items = debts.filter { $0.kind == kind }
                        if !items.isEmpty {
                            Section(t.kindPlural(kind)) {
                                ForEach(items) { debt in
                                    NavigationLink {
                                        DebtDetailView(debt: debt)
                                    } label: {
                                        DebtRow(debt: debt)
                                    }
                                    .contextMenu {
                                        Button(t.delete, role: .destructive) {
                                            delete(debt)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(t.debts)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    addMenuItems
                } label: {
                    Label(t.add, systemImage: "plus")
                }
            }
        }
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

    private func delete(_ debt: Debt) {
        context.delete(debt)
        try? context.save()
    }
}

private struct DebtRow: View {
    @Environment(\.l10n) private var t
    let debt: Debt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: debt.kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(debt.name)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(t.money(debt.totalOwed))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        switch debt.kind {
        case .creditCard:
            return t.dueShort + " " + t.shortDate(debt.nextDueDate)
        case .mortgage, .studentLoan:
            return [
                t.percent(debt.interestRate),
                t.perMonth(debt.monthlyPayment),
                t.interestShort(debt.amortization.interestThisMonth),
            ].joined(separator: " · ")
        }
    }
}
