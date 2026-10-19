import Foundation

/// Periodo de la gráfica de una categoría de deudas.
enum HistoryRange: String, CaseIterable, Identifiable {
    case threeMonths
    case sixMonths
    case year
    case all

    static let storageKey = "debts.historyRange"

    var id: String { rawValue }

    /// Meses hacia atrás; nil es desde la deuda más vieja.
    var months: Int? {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .year: return 12
        case .all: return nil
        }
    }
}
