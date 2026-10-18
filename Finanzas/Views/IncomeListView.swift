import SwiftUI
import SwiftData

struct IncomeListView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.createdAt) private var incomes: [Income]
    @State private var newKind: IncomeKind?
    @State private var editingIncome: Income?

    var body: some View {
        Group {
            if incomes.isEmpty {
                ContentUnavailableView {
                    Label(t.noIncomeTitle, systemImage: "tray")
                } description: {
                    Text(t.noIncomeMessage)
                } actions: {
                    Menu(t.add) { addMenuItems }
                        .fixedSize()
                }
            } else {
                List {
                    Section {
                        LabeledContent(t.monthlyIncome) {
                            Text(t.money(incomes.monthlyIncome))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        let extras = incomes.extrasTotal()
                        if extras > 0 {
                            LabeledContent(t.extrasThisMonth) {
                                Text(t.money(extras))
                                    .monospacedDigit()
                            }
                        }
                    }

                    ForEach(IncomeKind.allCases) { kind in
                        let items = sorted(incomes.filter { $0.kind == kind })
                        if !items.isEmpty {
                            Section {
                                ForEach(items) { income in
                                    Button {
                                        editingIncome = income
                                    } label: {
                                        IncomeRow(income: income)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(t.edit) { editingIncome = income }
                                        Button(t.delete, role: .destructive) {
                                            delete(income)
                                        }
                                    }
                                }
                            } header: {
                                Text(t.incomeKindPlural(kind))
                                    .appFont(.headline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(t.income)
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
            IncomeFormView(kind: kind)
        }
        .sheet(item: $editingIncome) { income in
            IncomeFormView(kind: income.kind, income: income)
        }
    }

    @ViewBuilder
    private var addMenuItems: some View {
        ForEach(IncomeKind.allCases) { kind in
            Button {
                newKind = kind
            } label: {
                Label(t.incomeKindName(kind), systemImage: kind.systemImage)
            }
        }
    }

    /// Recurrentes en el orden en que se agregaron; extras del más reciente al más viejo.
    private func sorted(_ items: [Income]) -> [Income] {
        guard items.first?.kind == .extra else { return items }
        return items.sorted { $0.date > $1.date }
    }

    private func delete(_ income: Income) {
        context.delete(income)
        try? context.save()
    }
}

private struct IncomeRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    let income: Income

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: income.kind.systemImage)
                .appFont(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32 * scale)
            VStack(alignment: .leading, spacing: 2) {
                Text(income.name.isEmpty ? t.incomeKindName(income.kind) : income.name)
                    .appFont(.body, weight: .medium)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(t.money(income.amount))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        switch income.kind {
        case .recurring:
            return t.frequencyName(income.frequency) + " · " + t.approxPerMonth(income.monthlyAmount)
        case .extra:
            return t.date(income.date)
        }
    }
}
