import SwiftUI
import SwiftData

/// Movimientos de las cuentas por mes, del más reciente al más viejo.
struct HistoryView: View {
    @Environment(\.l10n) private var t
    @Query(sort: \Movement.date, order: .reverse) private var movements: [Movement]
    let showsAccount: Bool

    @State private var editing: Movement?

    var body: some View {
        if movements.isEmpty {
            ContentUnavailableView(
                t.noMovementsTitle,
                systemImage: "clock",
                description: Text(t.noMovementsMessage)
            )
        } else {
            List {
                ForEach(months, id: \.start) { month in
                    Section {
                        ForEach(month.items) { movement in
                            MovementRow(movement: movement, showsAccount: showsAccount)
                                .onTapGesture {
                                    if isEditable(movement) { editing = movement }
                                }
                                .contextMenu {
                                    if isEditable(movement) {
                                        Button(t.edit) { editing = movement }
                                    }
                                    Button(t.delete, role: .destructive) { movement.remove() }
                                }
                                .swipeActions {
                                    Button(t.delete, role: .destructive) { movement.remove() }
                                }
                        }
                    } header: {
                        Text(t.monthYearLong(month.start))
                            .appFont(.headline)
                    }
                }
            }
            .sheet(item: $editing) { movement in
                MovementFormView(kind: movement.kind, movement: movement)
            }
        }
    }

    private var months: [(start: Date, items: [Movement])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: movements) {
            calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date
        }
        return groups.keys.sorted(by: >).map { (start: $0, items: groups[$0] ?? []) }
    }

    /// Los pagos y transferencias solo se pueden borrar (al pago se le regresa el monto a la deuda);
    /// para corregir uno, se borra y se registra de nuevo.
    private func isEditable(_ movement: Movement) -> Bool {
        movement.kind != .payment && movement.kind != .transfer
    }
}

private struct MovementRow: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    let movement: Movement
    let showsAccount: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: movement.kind.systemImage)
                .appFont(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32 * scale)
            VStack(alignment: .leading, spacing: 2) {
                Text(movement.note.isEmpty ? t.movementKindName(movement.kind) : movement.note)
                    .appFont(.body, weight: .medium)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Una transferencia no entra ni sale del total: solo cambia de cuenta.
            if movement.kind == .transfer {
                Text(t.money(movement.amount))
                    .monospacedDigit()
            } else {
                Text(t.signedMoney(movement.signedAmount))
                    .monospacedDigit()
                    .foregroundStyle(movement.signedAmount < 0 ? Color.primary : Color.green)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        switch movement.kind {
        case .payment: return .orange
        case .transfer: return .blue
        case .deposit, .extra: return .green
        }
    }

    private var subtitle: String {
        var parts = [t.date(movement.date)]
        if !movement.note.isEmpty {
            parts.insert(t.movementKindName(movement.kind), at: 0)
        }
        if movement.kind == .transfer {
            parts.append(t.route(from: movement.account?.name ?? "", to: movement.toAccount?.name ?? ""))
        } else if showsAccount, let account = movement.account {
            parts.append(account.name)
        }
        return parts.joined(separator: " · ")
    }
}
