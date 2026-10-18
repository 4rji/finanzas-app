import Foundation

enum DebtKind: String, CaseIterable, Identifiable, Codable {
    case creditCard
    case mortgage
    case studentLoan

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .creditCard: return "creditcard"
        case .mortgage: return "house"
        case .studentLoan: return "graduationcap"
        }
    }

    var isLoan: Bool { self != .creditCard }
}
