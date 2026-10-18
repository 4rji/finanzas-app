import Foundation

/// Tipo de cuenta: de cheques (o débito), una inversión como 401(k), FSA o acciones, o una meta de
/// ahorro (una cuenta de ahorro o inversión con un monto por juntar).
enum AccountKind: String, CaseIterable, Identifiable {
    case checking
    case investment
    case goal

    var id: String { rawValue }

    /// Inversión o meta: se muestran juntas en Inversiones y metas.
    var isSavings: Bool { self != .checking }

    var systemImage: String {
        switch self {
        case .checking: return "building.columns"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .goal: return "target"
        }
    }
}
