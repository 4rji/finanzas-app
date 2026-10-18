import Foundation

/// Tipo de ingreso.
enum IncomeKind: String, CaseIterable, Identifiable {
    /// Ingreso fijo que llega cada cierto tiempo, como el sueldo.
    case recurring
    /// Ingreso de una sola vez, como un bono o una venta.
    case extra

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .recurring: return "repeat"
        case .extra: return "plus.circle"
        }
    }
}

/// Cada cuánto llega un ingreso recurrente.
enum PayFrequency: String, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case semimonthly
    case monthly

    var id: String { rawValue }

    /// Pagos promedio por mes: 52 semanas ÷ 12, 26 catorcenas ÷ 12, etc.
    var paymentsPerMonth: Double {
        switch self {
        case .weekly: return 52.0 / 12
        case .biweekly: return 26.0 / 12
        case .semimonthly: return 2
        case .monthly: return 1
        }
    }
}
