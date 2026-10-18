import SwiftUI
import SwiftData

private enum AccountsTab: String, CaseIterable, Identifiable {
    case balance
    case history

    var id: String { rawValue }
}

/// Lo que se puede agregar desde la barra de arriba.
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
        .safeAreaInset(edge: .top) {
            TabHeader(caption: t.totalBalance, amount: accounts.totalBalance) {
                Picker(t.accounts, selection: $tab) {
                    Text(t.balance).tag(AccountsTab.balance)
                    Text(t.history).tag(AccountsTab.history)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            } trailing: {
                Button {
                    newItem = .transfer
                } label: {
                    Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                }
                .glassButton()
                .disabled(allAccounts.isEmpty)
                addMenu
            }
        }
        .screenBackground()
        .navigationTitle(t.accounts)
        .hideAmountsToolbar()
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

    private var addMenu: some View {
        Menu {
            Button {
                newItem = .account
            } label: {
                Label(t.account, systemImage: AccountKind.checking.systemImage)
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
        .menuStyle(.button)
        .prominentButton()
        .fixedSize()
    }
}

private struct AccountSummaryView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringIncome.createdAt) private var allIncomes: [RecurringIncome]
    @Query(sort: \RecurringPayment.createdAt) private var allAutoPayments: [RecurringPayment]
    @Query private var movements: [Movement]

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

                let summary = MonthSummary(movements: movements, incomes: allIncomes, autoPayments: allAutoPayments)
                Section {
                    MonthSummaryGrid(summary: summary)
                } header: {
                    Text(t.monthSummaryTitle(summary.month))
                        .sectionTitle()
                } footer: {
                    Text(t.monthSummaryFooter)
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

/// Ingresos, pagos y neto del mes: lo que va hasta hoy y el pronóstico para todo el mes.
private struct MonthSummaryGrid: View {
    @Environment(\.l10n) private var t
    @Environment(\.colorScheme) private var scheme
    let summary: MonthSummary

    var body: some View {
        Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 10) {
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                columnTitle(t.soFar)
                columnTitle(t.forecast)
            }
            GridRow {
                rowTitle(t.summaryIncome)
                amount(t.money(summary.income), color: ThemeTint.mint.solid(scheme))
                amount(t.money(summary.expectedIncome), color: ThemeTint.mint.solid(scheme))
            }
            GridRow {
                rowTitle(t.summaryPayments)
                amount(spent(summary.payments), color: ThemeTint.peach.solid(scheme))
                amount(spent(summary.expectedPayments), color: ThemeTint.peach.solid(scheme))
            }
            Divider()
                .gridCellUnsizedAxes(.horizontal)
            GridRow {
                rowTitle(t.summaryNet)
                amount(t.money(summary.net), color: netColor(summary.net), weight: .heavy)
                amount(t.money(summary.expectedNet), color: netColor(summary.expectedNet), weight: .heavy)
            }
        }
        .padding(.vertical, 6)
    }

    private func columnTitle(_ text: String) -> some View {
        Text(text)
            .sectionTitle()
            .lineLimit(1)
    }

    private func rowTitle(_ text: String) -> some View {
        Text(text)
            .appFont(.body, weight: .semibold)
            .gridColumnAlignment(.leading)
    }

    private func amount(_ text: String, color: Color, weight: Font.Weight = .bold) -> some View {
        Text(text)
            .appFont(.title3, weight: weight)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    /// "−$500.00"; sin signo si es 0.
    private func spent(_ value: Double) -> String {
        value > 0 ? "−" + t.money(value) : t.money(0)
    }

    private func netColor(_ value: Double) -> Color {
        value < 0 ? .red : .primary
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
