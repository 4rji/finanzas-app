import Foundation

enum DebtKind: String, CaseIterable, Identifiable, Codable {
    case creditCard
    case mortgage
    case autoLoan
    case studentLoan

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .creditCard: return "creditcard"
        case .mortgage: return "house"
        case .autoLoan: return "car"
        case .studentLoan: return "graduationcap"
        }
    }
}
