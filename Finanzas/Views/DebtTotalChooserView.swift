import SwiftUI
import SwiftData

/// Elige qué deudas se suman a la deuda total, por categoría completa o una por una. Las que se
/// quitan pasan a "Fuera del total".
struct DebtTotalChooserView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Environment(\.textScale) private var scale
    @Query(sort: \Debt.createdAt) private var debts: [Debt]

    /// Las que se suman; nil hasta el primer cambio, para arrancar con las que hoy se suman.
    @State private var edited: Set<PersistentIdentifier>?

    private var included: Set<PersistentIdentifier> {
        edited ?? Set(debts.filter { !$0.excludedFromTotal }.map(\.persistentModelID))
    }

    private var selectedTotal: Double {
        debts.filter { included.contains($0.persistentModelID) }.reduce(0) { $0 + $1.totalOwed }
    }

    var body: some View {
        FormSheet(onSave: save) {
            Section {
                LabeledContent(t.totalDebt) {
                    Text(t.money(selectedTotal))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            } header: {
                Text(t.chooseTotalTitle)
                    .sectionTitle()
            } footer: {
                Text(t.chooseTotalFooter)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(DebtKind.allCases) { kind in
                let items = debts.filter { $0.kind == kind }
                if !items.isEmpty {
                    Section {
                        categoryRow(kind, items: items)
                        ForEach(items) { debt in
                            debtRow(debt)
                        }
                    }
                }
            }
        }
    }

    /// Prende o apaga toda la categoría. Si solo algunas están, las prende todas.
    private func categoryRow(_ kind: DebtKind, items: [Debt]) -> some View {
        let ids = items.map(\.persistentModelID)
        let count = ids.filter { included.contains($0) }.count
        let allOn = count == ids.count

        return Button {
            var set = included
            if allOn {
                set.subtract(ids)
            } else {
                set.formUnion(ids)
            }
            edited = set
        } label: {
            HStack(spacing: 12) {
                IconTile(systemImage: kind.systemImage, tint: kind.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.kindPlural(kind))
                        .appFont(.body, weight: .semibold)
                    Text(t.debtCount(items.count) + " · " + t.money(items.reduce(0) { $0 + $1.totalOwed }))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                check(allOn ? "checkmark.circle.fill" : count > 0 ? "minus.circle.fill" : "circle", isOn: count > 0)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(allOn ? .isSelected : [])
    }

    private func debtRow(_ debt: Debt) -> some View {
        let id = debt.persistentModelID
        let isOn = included.contains(id)

        return Button {
            var set = included
            if isOn {
                set.remove(id)
            } else {
                set.insert(id)
            }
            edited = set
        } label: {
            HStack(spacing: 12) {
                Text(debt.name)
                    .appFont(.body)
                Spacer()
                Text(t.money(debt.totalOwed))
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                check(isOn ? "checkmark.circle.fill" : "circle", isOn: isOn)
            }
            // Debajo del nombre de la categoría, después de su ícono.
            .padding(.leading, 46 * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func check(_ systemImage: String, isOn: Bool) -> some View {
        Image(systemName: systemImage)
            .appFont(.title3, weight: .semibold)
            .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
            .accessibilityHidden(true)
    }

    private func save() {
        let ids = included
        for debt in debts {
            debt.excludedFromTotal = !ids.contains(debt.persistentModelID)
        }
        try? context.save()
    }
}
