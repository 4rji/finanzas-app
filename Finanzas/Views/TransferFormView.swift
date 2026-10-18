import SwiftUI
import SwiftData

/// Mueve dinero entre cuentas e inversiones, una vez o cada cierto tiempo. El dinero también puede
/// venir de otro lugar, como el sueldo: entonces solo se suma a la cuenta de destino. Si se repite,
/// se guarda como ingreso recurrente con `fromAccount` y se aplica solo en cada fecha.
struct TransferFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    let recurring: RecurringIncome?

    @State private var from: Account?
    /// Se eligió "otro lugar" como origen.
    @State private var fromOutside: Bool
    @State private var to: Account?
    @State private var amountText: String
    @State private var note: String
    @State private var date = Date()
    @State private var repeats: Bool
    @State private var frequency: PayFrequency
    @State private var startDate: Date

    init(to: Account? = nil, repeats: Bool = false) {
        recurring = nil
        _from = State(initialValue: nil)
        _fromOutside = State(initialValue: false)
        _to = State(initialValue: to)
        _amountText = State(initialValue: "")
        _note = State(initialValue: "")
        _repeats = State(initialValue: repeats)
        _frequency = State(initialValue: .weekly)
        _startDate = State(initialValue: Date())
    }

    init(recurring: RecurringIncome) {
        self.recurring = recurring
        _from = State(initialValue: recurring.fromAccount)
        _fromOutside = State(initialValue: recurring.fromAccount == nil)
        _to = State(initialValue: recurring.account)
        _amountText = State(initialValue: editText(recurring.amount))
        _note = State(initialValue: recurring.name)
        _repeats = State(initialValue: true)
        _frequency = State(initialValue: recurring.frequency)
        _startDate = State(initialValue: recurring.startDate)
    }

    private var amount: Double { parseDecimal(amountText) }

    /// Cuenta de origen; nil = otro lugar. Sin elegir, la primera de cheques que no sea el destino.
    private var source: Account? {
        if fromOutside { return nil }
        if let from { return from }
        guard accounts.count > 1 else { return nil }
        return accounts.first { $0.kind == .checking && $0 != to } ?? accounts.first { $0 != to }
    }

    private var destination: Account? {
        to ?? accounts.first { $0 != source }
    }

    private var canSave: Bool {
        amount > 0 && destination != nil && destination != source
    }

    private var scheduleChanged: Bool {
        guard let recurring else { return true }
        return frequency != recurring.frequency
            || !Calendar.current.isDate(startDate, inSameDayAs: recurring.startDate)
    }

    /// Próxima fecha calculada con la fecha de inicio y la frecuencia elegidas.
    private var nextPayDate: Date {
        if let recurring, !scheduleChanged { return recurring.nextPayDate }
        let n = frequency.firstPayIndex(onOrAfter: Date(), from: startDate)
        return frequency.payDate(n, from: startDate)
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save, onDelete: recurring == nil ? nil : delete) {
            Section {
                Picker(t.fromLabel, selection: Binding(get: { source }, set: { setSource($0) })) {
                    Text(t.outsideSource).tag(Account?.none)
                    ForEach(accounts) { account in
                        Text(account.name).tag(Optional(account))
                    }
                }
                Picker(t.toLabel, selection: Binding(get: { destination }, set: { to = $0 })) {
                    ForEach(accounts.filter { $0 != source }) { account in
                        Text(account.name).tag(Optional(account))
                    }
                }
                DecimalField(title: t.amount, text: $amountText, prefix: t.currencySymbol)
                TextRow(title: t.descriptionOptional, text: $note, prompt: t.moveNotePlaceholder)

                // Los datos de la repetición solo aparecen con la casilla activada.
                if recurring == nil {
                    Toggle(t.repeats, isOn: $repeats)
                        .checkboxStyle()
                }
                if repeats {
                    Picker(t.howOften, selection: $frequency) {
                        ForEach(PayFrequency.allCases) { option in
                            Text(t.frequencyName(option)).tag(option)
                        }
                    }
                    DateField(title: t.startDate, date: $startDate)
                } else {
                    DateField(title: t.dateLabel, date: $date)
                }
            } header: {
                Label(t.moveMoney, systemImage: MovementKind.transfer.systemImage)
                    .sectionTitle()
            } footer: {
                Text(repeats ? t.moveMoneyFooter + " " + t.moveRecurringFooter : t.moveMoneyFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                if accounts.isEmpty {
                    Label(t.needsAccount, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if repeats {
                    LabeledContent(t.nextDeposit, value: t.date(nextPayDate))
                    LabeledContent(t.monthlyAmountApprox, value: t.money(amount * frequency.paymentsPerMonth))
                } else {
                    if let source {
                        LabeledContent(t.balanceAfter(source.name), value: t.money(source.balance - amount))
                    }
                    if let destination {
                        LabeledContent(t.balanceAfter(destination.name), value: t.money(destination.balance + amount))
                    }
                }
            }
        }
    }

    private func setSource(_ account: Account?) {
        // Si el nuevo origen era el destino, el destino pasa a otra cuenta.
        if let account, account == destination { to = nil }
        fromOutside = account == nil
        from = account
    }

    private func save() {
        guard let destination else { return }
        let source = self.source
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if repeats {
            let target: RecurringIncome
            if let recurring {
                target = recurring
            } else {
                target = RecurringIncome(name: trimmedNote)
                context.insert(target)
            }

            let reschedule = scheduleChanged
            let defaultName = destination.kind.isSavings ? t.contribution : t.transfer
            target.name = trimmedNote.isEmpty ? defaultName : trimmedNote
            target.amount = amount
            target.account = destination
            target.fromAccount = source
            if reschedule {
                target.reschedule(start: startDate, frequency: frequency)
            }
            try? context.save()
            RecurringDeposits.update(in: context)
        } else {
            // Si viene de otro lugar solo entra dinero: es un ingreso extra de la cuenta de destino.
            let movement = Movement(kind: source == nil ? .extra : .transfer)
            context.insert(movement)
            movement.amount = amount
            movement.date = date
            movement.note = trimmedNote
            movement.account = source ?? destination
            movement.toAccount = source == nil ? nil : destination
            try? context.save()
        }
    }

    private func delete() {
        guard let recurring else { return }
        context.delete(recurring)
        try? context.save()
    }
}
