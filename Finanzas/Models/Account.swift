import Foundation
import SwiftData

/// Cuenta de cheques (o débito) o inversión. El saldo no se guarda: es el saldo inicial más los
/// movimientos, así los depósitos y pagos que llegan de otro dispositivo se suman sin pisarse.
@Model
final class Account {
    var name: String = ""
    var kindRaw: String = "checking"
    var createdAt: Date = Date()
    var startingBalance: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \Movement.account)
    var movements: [Movement]? = []

    /// Transferencias que llegan de otra cuenta. Si se borra esta cuenta, siguen en la de origen.
    @Relationship(deleteRule: .nullify, inverse: \Movement.toAccount)
    var incomingTransfers: [Movement]? = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringIncome.account)
    var incomes: [RecurringIncome]? = []

    /// Transferencias recurrentes que salen de esta cuenta.
    @Relationship(deleteRule: .cascade, inverse: \RecurringIncome.fromAccount)
    var outgoingRecurring: [RecurringIncome]? = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringPayment.account)
    var autoPayments: [RecurringPayment]? = []

    init(name: String, kind: AccountKind = .checking) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .checking }
        set { kindRaw = newValue.rawValue }
    }

    var balance: Double {
        startingBalance
            + (movements ?? []).reduce(0) { $0 + $1.signedAmount }
            + (incomingTransfers ?? []).reduce(0) { $0 + $1.amount }
    }

    /// Ajusta el saldo inicial para que el saldo actual quede en `value`, sin tocar el historial.
    func setBalance(_ value: Double) {
        startingBalance += value - balance
    }
}

extension Sequence where Element == Account {
    var checking: [Account] { filter { $0.kind == .checking } }
    var investments: [Account] { filter { $0.kind == .investment } }

    var totalBalance: Double {
        reduce(0) { $0 + $1.balance }
    }
}
