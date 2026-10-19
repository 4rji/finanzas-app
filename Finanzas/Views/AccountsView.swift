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
    /// El cobro del seguro se cambia desde el préstamo.
    @State private var editingInsuranceDebt: Debt?

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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(t.balance)
                            .sectionTitle()
                        AccountCardCarousel(accounts: accounts) { editingAccount = $0 }
                    }

                    AccountSection(
                        title: t.recurringIncome,
                        footer: incomes.monthlyIncome > 0
                            ? t.monthlyIncome + ": " + t.money(incomes.monthlyIncome) : nil
                    ) {
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if !autoPayments.isEmpty {
                        AccountSection(title: t.autoPayments) {
                            ForEach(autoPayments) { plan in
                                Button {
                                    edit(plan)
                                } label: {
                                    AutoPaymentRow(plan: plan)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(t.edit) { edit(plan) }
                                    Button(t.delete, role: .destructive) { delete(plan) }
                                }
                            }
                        }
                    }

                    AccountSection(footer: t.historyHint) {
                        Button {
                            onAdd(.extra)
                        } label: {
                            Label(t.addExtraIncome, systemImage: MovementKind.extra.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                        }
                        Button {
                            onAdd(.payment)
                        } label: {
                            Label(t.recordPayment, systemImage: MovementKind.payment.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                        }
                        .disabled(!canPay)
                        Button {
                            onAdd(.transfer)
                        } label: {
                            Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)

                    let summary = MonthSummary(movements: movements, incomes: allIncomes, autoPayments: allAutoPayments)
                    AccountSection(title: t.monthSummaryTitle(summary.month), footer: t.monthSummaryFooter) {
                        MonthSummaryGrid(summary: summary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .sheet(item: $editingInsuranceDebt) { debt in
                DebtFormView(kind: debt.kind, debt: debt)
            }
        }
    }

    private func delete(_ income: RecurringIncome) {
        context.delete(income)
        try? context.save()
    }

    private func edit(_ plan: RecurringPayment) {
        if plan.isInsurance {
            editingInsuranceDebt = plan.debt
        } else {
            editingAutoPayment = plan
        }
    }

    private func delete(_ plan: RecurringPayment) {
        context.delete(plan)
        try? context.save()
    }
}

/// Superficie que ocupa el ancho disponible sin las restricciones de un formulario agrupado.
private struct AccountSection<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let title: String?
    let footer: String?
    let content: Content

    init(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .sectionTitle()
            }
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .appFont(.body)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(scheme == .dark ? Color(hex: 0x1A261F) : .white, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
            if let footer {
                Text(footer)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                Label(title, systemImage: plan.isInsurance ? "shield" : plan.debt?.kind.systemImage ?? "creditcard")
                    .appFont(.body, weight: .medium)
                Spacer()
                Text(t.money(plan.amount))
                    .monospacedDigit()
            }
            Text(summary)
                .appFont(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var title: String {
        let name = plan.debt?.name ?? ""
        return plan.isInsurance ? t.insuranceOf(name) : name
    }

    private var summary: String {
        let account = plan.account?.name ?? ""
        guard plan.isInsurance, let debt = plan.debt else {
            return t.autoPaySummary(amount: plan.amount, account: account, next: plan.nextPayDate)
        }
        return t.insuranceChargeSummary(amount: plan.amount, frequency: debt.insuranceFrequency, account: account, next: plan.nextPayDate)
    }
}
