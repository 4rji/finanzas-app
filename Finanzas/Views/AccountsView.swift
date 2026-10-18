import SwiftUI
import SwiftData

private enum AccountsTab: String, CaseIterable, Identifiable {
    case balance
    case history

    var id: String { rawValue }
}

/// Lo que se puede agregar con el botón +.
private enum NewItem: String, Identifiable {
    case account
    case income
    case extra
    case payment

    var id: String { rawValue }
}

/// Cuentas con su saldo e ingresos recurrentes; los movimientos van en la pestaña Historial.
struct AccountsView: View {
    @Environment(\.l10n) private var t
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var debts: [Debt]

    @State private var tab: AccountsTab = .balance
    @State private var newItem: NewItem?

    var body: some View {
        Group {
            switch tab {
            case .balance:
                AccountSummaryView(accounts: accounts, canPay: !debts.isEmpty) { newItem = $0 }
            case .history:
                HistoryView(showsAccount: accounts.count > 1)
            }
        }
        .navigationTitle(t.accounts)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker(t.accounts, selection: $tab) {
                    Text(t.balance).tag(AccountsTab.balance)
                    Text(t.history).tag(AccountsTab.history)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        newItem = .account
                    } label: {
                        Label(t.account, systemImage: "building.columns")
                    }
                    Button {
                        newItem = .income
                    } label: {
                        Label(t.recurringIncomeItem, systemImage: "repeat")
                    }
                    .disabled(accounts.isEmpty)
                    Button {
                        newItem = .extra
                    } label: {
                        Label(t.extraIncome, systemImage: MovementKind.extra.systemImage)
                    }
                    .disabled(accounts.isEmpty)
                    Button {
                        newItem = .payment
                    } label: {
                        Label(t.recordPayment, systemImage: MovementKind.payment.systemImage)
                    }
                    .disabled(accounts.isEmpty || debts.isEmpty)
                } label: {
                    Label(t.add, systemImage: "plus")
                }
            }
        }
        .sheet(item: $newItem) { item in
            switch item {
            case .account: AccountFormView()
            case .income: RecurringIncomeFormView()
            case .extra: MovementFormView(kind: .extra)
            case .payment: PaymentFormView()
            }
        }
    }
}

private struct AccountSummaryView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringIncome.createdAt) private var incomes: [RecurringIncome]

    let accounts: [Account]
    let canPay: Bool
    let onAdd: (NewItem) -> Void

    @State private var editingAccount: Account?
    @State private var editingIncome: RecurringIncome?

    var body: some View {
        if accounts.isEmpty {
            ContentUnavailableView {
                Label(t.noAccountsTitle, systemImage: "building.columns")
            } description: {
                Text(t.noAccountsMessage)
            } actions: {
                Button(t.addAccount) { onAdd(.account) }
            }
        } else {
            Form {
                Section {
                    ForEach(accounts) { account in
                        Button {
                            editingAccount = account
                        } label: {
                            AccountRow(account: account)
                        }
                        .buttonStyle(.plain)
                    }
                    if accounts.count > 1 {
                        LabeledContent(t.totalBalance) {
                            Text(t.money(accounts.reduce(0) { $0 + $1.balance }))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text(t.balance)
                        .appFont(.headline)
                }

                Section {
                    if incomes.isEmpty {
                        Text(t.noRecurringIncome)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(incomes) { income in
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
                        onAdd(.income)
                    } label: {
                        Label(t.addRecurringIncome, systemImage: "plus")
                    }
                } header: {
                    Text(t.recurringIncome)
                        .appFont(.headline)
                } footer: {
                    if !incomes.isEmpty {
                        Text(t.monthlyIncome + ": " + t.money(incomes.monthlyIncome))
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        onAdd(.extra)
                    } label: {
                        Label(t.addExtraIncome, systemImage: MovementKind.extra.systemImage)
                    }
                    Button {
                        onAdd(.payment)
                    } label: {
                        Label(t.recordPayment, systemImage: MovementKind.payment.systemImage)
                    }
                    .disabled(!canPay)
                } footer: {
                    Text(t.historyHint)
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .sheet(item: $editingAccount) { account in
                AccountFormView(account: account)
            }
            .sheet(item: $editingIncome) { income in
                RecurringIncomeFormView(income: income)
            }
        }
    }

    private func delete(_ income: RecurringIncome) {
        context.delete(income)
        try? context.save()
    }
}

private struct AccountRow: View {
    @Environment(\.l10n) private var t
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            Label(account.name, systemImage: "building.columns")
                .appFont(.body, weight: .medium)
            Spacer()
            Text(t.money(account.balance))
                .appFont(.title3, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(account.balance < 0 ? Color.red : Color.primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct RecurringIncomeRow: View {
    @Environment(\.l10n) private var t
    let income: RecurringIncome

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Label(income.name, systemImage: "repeat")
                    .appFont(.body, weight: .medium)
                Spacer()
                Text(t.money(income.amount))
                    .monospacedDigit()
            }
            Text([
                t.frequencyName(income.frequency),
                t.nextDeposit + " " + t.date(income.nextPayDate),
                t.approxPerMonth(income.monthlyAmount),
            ].joined(separator: " · "))
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
