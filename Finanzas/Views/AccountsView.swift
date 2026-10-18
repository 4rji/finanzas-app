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
    case transfer

    var id: String { rawValue }
}

/// Cuentas con su saldo e ingresos recurrentes; los movimientos van en la pestaña Historial.
struct AccountsView: View {
    @Environment(\.l10n) private var t
    @Query(sort: \Account.createdAt) private var allAccounts: [Account]
    @Query private var debts: [Debt]

    @State private var tab: AccountsTab = .balance
    @State private var newItem: NewItem?

    /// Las inversiones van en su propia pantalla.
    private var accounts: [Account] { allAccounts.checking }

    var body: some View {
        Group {
            switch tab {
            case .balance:
                AccountSummaryView(accounts: accounts, canPay: !debts.isEmpty) { newItem = $0 }
            case .history:
                HistoryView(showsAccount: allAccounts.count > 1)
            }
        }
        .screenBackground()
        .navigationTitle(t.accounts)
        .hideAmountsToolbar()
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
                    Button {
                        newItem = .transfer
                    } label: {
                        Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                    }
                    .disabled(allAccounts.isEmpty)
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
            case .transfer: TransferFormView()
            }
        }
    }
}

private struct AccountSummaryView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringIncome.createdAt) private var allIncomes: [RecurringIncome]
    @Query(sort: \RecurringPayment.createdAt) private var allAutoPayments: [RecurringPayment]

    let accounts: [Account]
    let canPay: Bool
    let onAdd: (NewItem) -> Void

    @State private var editingAccount: Account?
    @State private var editingIncome: RecurringIncome?
    @State private var editingAutoPayment: RecurringPayment?

    /// Los aportes y transferencias de inversiones se ven en Inversiones.
    private var incomes: [RecurringIncome] { allIncomes.filter { !$0.isInvestment } }
    private var autoPayments: [RecurringPayment] { allAutoPayments.filter { $0.debt != nil } }

    var body: some View {
        if accounts.isEmpty {
            ContentUnavailableView {
                Label(t.noAccountsTitle, systemImage: "building.columns")
            } description: {
                Text(t.noAccountsMessage)
            } actions: {
                Button(t.addAccount) { onAdd(.account) }
                    .prominentButton()
            }
        } else {
            ThemedForm {
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
                        .sectionTitle()
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
                        .sectionTitle()
                } footer: {
                    if incomes.monthlyIncome > 0 {
                        Text(t.monthlyIncome + ": " + t.money(incomes.monthlyIncome))
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !autoPayments.isEmpty {
                    Section {
                        ForEach(autoPayments) { plan in
                            Button {
                                editingAutoPayment = plan
                            } label: {
                                AutoPaymentRow(plan: plan)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(t.edit) { editingAutoPayment = plan }
                                Button(t.delete, role: .destructive) { delete(plan) }
                            }
                        }
                    } header: {
                        Text(t.autoPayments)
                            .sectionTitle()
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
                    Button {
                        onAdd(.transfer)
                    } label: {
                        Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                    }
                } footer: {
                    Text(t.historyHint)
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $editingAccount) { account in
                AccountFormView(account: account)
            }
            .sheet(item: $editingIncome) { income in
                if income.fromAccount != nil {
                    TransferFormView(recurring: income)
                } else {
                    RecurringIncomeFormView(income: income)
                }
            }
            .sheet(item: $editingAutoPayment) { plan in
                PaymentFormView(recurring: plan)
            }
        }
    }

    private func delete(_ income: RecurringIncome) {
        context.delete(income)
        try? context.save()
    }

    private func delete(_ plan: RecurringPayment) {
        context.delete(plan)
        try? context.save()
    }
}

/// Cuenta, inversión o meta con su tarjetita de color. Las metas muestran cuánto llevan.
struct AccountRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    let account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                CardChip(systemImage: account.kind.systemImage, tint: account.kind.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(account.name)
                        .appFont(.body, weight: .semibold)
                    Text(caption)
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(t.money(account.balance))
                    .appFont(.title3, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(account.balance < 0 ? Color.red : Color.primary)
            }

            if let progress = account.goalProgress {
                ProgressView(value: progress)
                    .tint(account.kind.tint.solid(scheme))
                Text(progress >= 1 ? t.goalReached : t.goalLeft(account.goalAmount - account.balance))
                    .appFont(.subheadline, weight: progress >= 1 ? .semibold : .regular)
                    .foregroundStyle(progress >= 1 ? account.kind.tint.solid(scheme) : Color.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var caption: String {
        if account.kind == .goal, account.goalAmount > 0 {
            return t.amountOf(account.balance, account.goalAmount)
        }
        return t.savingsKindName(account.kind)
    }
}

struct RecurringIncomeRow: View {
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
            Text(details.joined(separator: " · "))
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var details: [String] {
        var parts = [
            t.frequencyName(income.frequency),
            t.nextDeposit + " " + t.date(income.nextPayDate),
            t.approxPerMonth(income.monthlyAmount),
        ]
        // Las transferencias y los aportes dicen de dónde sale el dinero y a dónde llega.
        if income.fromAccount != nil || income.isInvestment {
            parts.insert(t.route(from: income.fromAccount?.name, to: income.account?.name ?? ""), at: 0)
        }
        return parts
    }
}

private struct AutoPaymentRow: View {
    @Environment(\.l10n) private var t
    let plan: RecurringPayment

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Label(plan.debt?.name ?? "", systemImage: plan.debt?.kind.systemImage ?? "creditcard")
                    .appFont(.body, weight: .medium)
                Spacer()
                Text(t.money(plan.amount))
                    .monospacedDigit()
            }
            Text(t.autoPaySummary(amount: plan.amount, account: plan.account?.name ?? "", next: plan.nextPayDate))
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
