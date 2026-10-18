import Foundation
import SwiftData

/// Cuenta de cheques o de débito. El saldo no se guarda: es el saldo inicial más los movimientos,
/// así los depósitos y pagos que llegan de otro dispositivo se suman sin pisarse.
@Model
final class Account {
    var name: String = ""
    var createdAt: Date = Date()
    var startingBalance: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \Movement.account)
    var movements: [Movement]? = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringIncome.account)
    var incomes: [RecurringIncome]? = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    var balance: Double {
        startingBalance + (movements ?? []).reduce(0) { $0 + $1.signedAmount }
    }

    /// Ajusta el saldo inicial para que el saldo actual quede en `value`, sin tocar el historial.
    func setBalance(_ value: Double) {
        startingBalance += value - balance
    }
}
