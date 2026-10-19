import Foundation

/// Cada cuánto se paga el seguro de un préstamo.
enum InsuranceFrequency: String, CaseIterable, Identifiable {
    case monthly
    case semiannual
    case annual

    var id: String { rawValue }

    /// Meses entre un cobro y el siguiente.
    var months: Int {
        switch self {
        case .monthly: return 1
        case .semiannual: return 6
        case .annual: return 12
        }
    }
}
