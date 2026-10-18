import Foundation

/// Tipo de cuenta: de cheques (o débito) o una inversión como 401(k), FSA o acciones.
enum AccountKind: String, CaseIterable, Identifiable {
    case checking
    case investment

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .checking: return "building.columns"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
}
