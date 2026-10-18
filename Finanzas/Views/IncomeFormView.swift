import SwiftUI
import SwiftData

/// Alta o edición de un ingreso recurrente o extra.
struct IncomeFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let kind: IncomeKind
    let income: Income?

    @State private var name: String
    @State private var amountText: String
    @State private var frequency: PayFrequency
    @State private var date: Date

    init(kind: IncomeKind, income: Income? = nil) {
        self.kind = kind
        self.income = income
        _name = State(initialValue: income?.name ?? "")
        _amountText = State(initialValue: editText(income?.amount ?? 0))
        _frequency = State(initialValue: income?.frequency ?? .weekly)
        _date = State(initialValue: income?.date ?? Date())
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var amount: Double { parseDecimal(amountText) }

    /// El extra puede ir sin descripción; el recurrente necesita nombre.
    private var canSave: Bool {
        amount > 0 && (kind == .extra || !trimmedName.isEmpty)
    }

    var body: some View {
        FormSheet(canSave: canSave, onSave: save, onDelete: income == nil ? nil : delete) {
            Section {
                switch kind {
                case .recurring:
                    TextRow(title: t.name, text: $name, prompt: t.incomeNamePlaceholder(kind))
                    DecimalField(title: t.amountPerPayment, text: $amountText, prefix: t.currencySymbol)
                    Picker(t.howOften, selection: $frequency) {
                        ForEach(PayFrequency.allCases) { option in
                            Text(t.frequencyName(option)).tag(option)
                        }
                    }
                case .extra:
                    TextRow(title: t.descriptionOptional, text: $name, prompt: t.incomeNamePlaceholder(kind))
                    DecimalField(title: t.amount, text: $amountText, prefix: t.currencySymbol)
                    DateField(title: t.dateReceived, date: $date)
                }
            } header: {
                Label(t.incomeKindName(kind), systemImage: kind.systemImage)
                    .appFont(.headline)
            } footer: {
                Text(kind == .recurring ? t.recurringIncomeFooter : t.extraIncomeFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if kind == .recurring {
                Section {
                    LabeledContent(t.monthlyIncome, value: t.money(amount * frequency.paymentsPerMonth))
                }
            }
        }
    }

    private func save() {
        let target: Income
        if let income {
            target = income
        } else {
            target = Income(name: trimmedName, kind: kind)
            context.insert(target)
        }

        target.name = trimmedName
        target.amount = amount
        switch kind {
        case .recurring:
            target.frequency = frequency
        case .extra:
            target.date = date
        }
        try? context.save()
    }

    private func delete() {
        guard let income else { return }
        context.delete(income)
        try? context.save()
    }
}
