import SwiftUI
import SwiftData

/// Lo que se puede agregar con el botón +.
private enum NewInvestmentItem: String, Identifiable {
    case investment
    case goal
    case transfer
    case contribution

    var id: String { rawValue }
}

/// Inversiones como 401(k), FSA o acciones, y metas de ahorro: solo nombre y valor (y en las metas,
/// cuánto se quiere juntar). El dinero entra o sale con transferencias desde otra cuenta o con
/// aportes recurrentes.
struct InvestmentsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query(sort: \RecurringIncome.createdAt) private var allIncomes: [RecurringIncome]

    @State private var newItem: NewInvestmentItem?
    @State private var editingAccount: Account?
    @State private var editingIncome: RecurringIncome?

    /// Inversiones y metas juntas, para mover dinero y aportar a cualquiera.
    private var investments: [Account] { allAccounts.investments }
    private var investmentsOnly: [Account] { investments.filter { $0.kind == .investment } }
    private var goals: [Account] { investments.filter { $0.kind == .goal } }
    private var contributions: [RecurringIncome] { allIncomes.filter(\.isInvestment) }

    var body: some View {
        Group {
            if investments.isEmpty {
                ContentUnavailableView {
                    Label(t.noInvestmentsTitle, systemImage: AccountKind.investment.systemImage)
                } description: {
                    Text(t.noInvestmentsMessage)
                } actions: {
                    Button(t.addInvestment) { newItem = .investment }
                        .prominentButton()
                    Button(t.addGoal) { newItem = .goal }
                }
            } else {
                summary
            }
        }
        .screenBackground()
        .navigationTitle(t.investments)
        .hideAmountsToolbar()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        newItem = .investment
                    } label: {
                        Label(t.investment, systemImage: AccountKind.investment.systemImage)
                    }
                    Button {
                        newItem = .goal
                    } label: {
                        Label(t.goal, systemImage: AccountKind.goal.systemImage)
                    }
                    Button {
                        newItem = .transfer
                    } label: {
                        Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                    }
                    .disabled(investments.isEmpty)
                    Button {
                        newItem = .contribution
                    } label: {
                        Label(t.recurringContribution, systemImage: "repeat")
                    }
                    .disabled(investments.isEmpty)
                } label: {
                    Label(t.add, systemImage: "plus")
                }
            }
        }
        .sheet(item: $newItem) { item in
            switch item {
            case .investment: AccountFormView(kind: .investment)
            case .goal: AccountFormView(kind: .goal)
            case .transfer: TransferFormView(to: investments.first)
            case .contribution: TransferFormView(to: investments.first, repeats: true)
            }
        }
    }

    private var summary: some View {
        ThemedForm {
            if !investmentsOnly.isEmpty {
                accountsSection(investmentsOnly, title: t.investmentsSection)
            }
            if !goals.isEmpty {
                accountsSection(goals, title: t.goals)
            }
            if investments.count > 1 {
                Section {
                    LabeledContent(t.totalValue) {
                        Text(t.money(investments.totalBalance))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
            }

            Section {
                if contributions.isEmpty {
                    Text(t.noRecurringContributions)
                        .foregroundStyle(.secondary)
                }
                ForEach(contributions) { income in
                    Button {
                        editingIncome = income
                    } label: {
                        RecurringIncomeRow(income: income)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(t.edit) { editingIncome = income }
                        Button(t.delete, role: .destructive) { delete(income) }
                    }
                }
                Button {
                    newItem = .contribution
                } label: {
                    Label(t.addRecurringContribution, systemImage: "plus")
                }
            } header: {
                Text(t.recurringContributions)
                    .sectionTitle()
            } footer: {
                if contributions.monthlyContributions > 0 {
                    Text(t.monthlyAmountApprox + ": " + t.money(contributions.monthlyContributions))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    newItem = .transfer
                } label: {
                    Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                }
            } footer: {
                Text(t.investmentsHistoryHint)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $editingAccount) { account in
            AccountFormView(account: account)
        }
        .sheet(item: $editingIncome) { income in
            TransferFormView(recurring: income)
        }
    }

    private func accountsSection(_ accounts: [Account], title: String) -> some View {
        Section {
            ForEach(accounts) { account in
                Button {
                    editingAccount = account
                } label: {
                    AccountRow(account: account)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(title)
                .sectionTitle()
        }
    }

    private func delete(_ income: RecurringIncome) {
        context.delete(income)
        try? context.save()
    }
}
