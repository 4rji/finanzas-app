import SwiftUI
import SwiftData

/// Alta o edición de un total personalizado: un nombre y las deudas que suma.
struct DebtGroupFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Debt.createdAt) private var allDebts: [Debt]

    let group: DebtGroup?

    @State private var name: String
    @State private var selected: Set<PersistentIdentifier>

    init(group: DebtGroup? = nil) {
        self.group = group
        _name = State(initialValue: group?.name ?? "")
        _selected = State(initialValue: Set((group?.debts ?? []).map(\.persistentModelID)))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Por categoría, como en la lista de deudas.
    private var debts: [Debt] {
        DebtKind.allCases.flatMap { kind in allDebts.filter { $0.kind == kind } }
    }

    private var chosen: [Debt] {
        debts.filter { selected.contains($0.persistentModelID) }
    }

    var body: some View {
        FormSheet(canSave: !trimmedName.isEmpty, onSave: save, onDelete: group == nil ? nil : delete) {
            Section {
                TextRow(title: t.name, text: $name, prompt: t.customTotalPlaceholder)
            } header: {
                Label(t.customTotal, systemImage: "square.stack.3d.up")
                    .sectionTitle()
            }

            Section {
                if debts.isEmpty {
                    Text(t.noDebtsTitle)
                        .foregroundStyle(.secondary)
                }
                ForEach(debts) { debt in
                    let isOn = selected.contains(debt.persistentModelID)
                    Button {
                        toggle(debt)
                    } label: {
                        HStack(spacing: 12) {
                            IconTile(systemImage: debt.kind.systemImage, tint: debt.kind.tint)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(debt.name)
                                    .appFont(.body, weight: .semibold)
                                Text(t.money(debt.totalOwed))
                                    .appFont(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Spacer()
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .appFont(.title3, weight: .semibold)
                                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            } header: {
                Text(t.debtsToAdd)
                    .sectionTitle()
            } footer: {
                Text(t.sumOf(chosen.reduce(0) { $0 + $1.totalOwed }))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toggle(_ debt: Debt) {
        let id = debt.persistentModelID
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }

    private func save() {
        let target: DebtGroup
        if let group {
            target = group
        } else {
            target = DebtGroup(name: trimmedName)
            context.insert(target)
        }
        target.name = trimmedName
        target.debts = chosen
        try? context.save()
    }

    private func delete() {
        guard let group else { return }
        context.delete(group)
        try? context.save()
    }
}
