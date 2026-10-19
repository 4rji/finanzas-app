import Foundation
import SwiftData

/// Total que arma el usuario con las deudas que elige, por ejemplo "Revolventes". Una deuda puede
/// estar en varios.
@Model
final class DebtGroup {
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(inverse: \Debt.groups)
    var debts: [Debt]? = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    /// Suma lo que se debe en cada deuda elegida, aunque esté fuera de la deuda total.
    var total: Double {
        (debts ?? []).reduce(0) { $0 + $1.totalOwed }
    }

    var sortedDebts: [Debt] {
        (debts ?? []).sorted { $0.createdAt < $1.createdAt }
    }
}
