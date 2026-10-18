import Foundation
import SwiftData

/// Cuenta de cheques (o débito), inversión o meta. El saldo no se guarda: es el saldo inicial más los
/// movimientos, así los depósitos y pagos que llegan de otro dispositivo se suman sin pisarse.
/// En una meta, `goalAmount` es lo que se quiere juntar.
@Model
final class Account {
    var name: String = ""
    var kindRaw: String = "checking"
    var createdAt: Date = Date()
    var startingBalance: Double = 0
    var goalAmount: Double = 0

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

    /// Avance de la meta, de 0 a 1. nil si no es meta o no tiene monto.
    var goalProgress: Double? {
        guard kind == .goal, goalAmount > 0 else { return nil }
        return min(max(balance / goalAmount, 0), 1)
    }

    /// Ajusta el saldo inicial para que el saldo actual quede en `value`, sin tocar el historial.
    func setBalance(_ value: Double) {
        startingBalance += value - balance
    }
}

extension Sequence where Element == Account {
    var checking: [Account] { filter { $0.kind == .checking } }
    /// Inversiones y metas.
    var investments: [Account] { filter { $0.kind.isSavings } }

    var totalBalance: Double {
        reduce(0) { $0 + $1.balance }
    }
}
