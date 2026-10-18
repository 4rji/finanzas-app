import Foundation

/// Tipo de movimiento de una cuenta.
enum MovementKind: String, CaseIterable, Identifiable {
    /// Depósito de un ingreso recurrente; se suma solo en cada fecha de pago.
    case deposit
    /// Ingreso de una sola vez, como un bono o una venta.
    case extra
    /// Pago a una tarjeta o crédito; sale de la cuenta.
    case payment

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .deposit: return "arrow.down.circle"
        case .extra: return "plus.circle"
        case .payment: return "arrow.up.circle"
        }
    }
}
