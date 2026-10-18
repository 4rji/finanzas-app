import Foundation

/// Tipo de saldo especial dentro de una tarjeta.
enum PlanKind: String, CaseIterable, Identifiable {
    /// Transferencia de saldo: saldo con tasa promocional hasta una fecha de vencimiento.
    case balanceTransfer
    /// Compra a meses: mensualidad fija durante N meses.
    case installments

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .installments: return "calendar"
        case .balanceTransfer: return "arrow.left.arrow.right"
        }
    }
}
