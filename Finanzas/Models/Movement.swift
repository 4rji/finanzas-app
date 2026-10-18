import Foundation
import SwiftData

/// Movimiento de una cuenta. Los campos se reutilizan según el tipo:
/// - Depósito: lo agrega solo un ingreso recurrente (`income`); `payDate` = fecha de pago que cubre.
/// - Ingreso extra: monto de una sola vez.
/// - Pago: sale de la cuenta hacia una deuda (`debt`); `appliedToDebt` = cuánto bajó su saldo.
/// `amount` siempre es positivo; el tipo dice si entra o sale.
@Model
final class Movement {
    var kindRaw: String = "extra"
    /// Identificador que no cambia entre dispositivos; sirve para quitar depósitos duplicados.
    var uuid: String = ""
    var createdAt: Date = Date()
    var amount: Double = 0
    var date: Date = Date()
    var note: String = ""
    var payDate: Date = Date()
    var appliedToDebt: Double = 0
    var account: Account?
    var income: RecurringIncome?
    var debt: Debt?

    init(kind: MovementKind) {
        self.kindRaw = kind.rawValue
        self.uuid = UUID().uuidString
        self.createdAt = Date()
    }

    var kind: MovementKind {
        get { MovementKind(rawValue: kindRaw) ?? .extra }
        set { kindRaw = newValue.rawValue }
    }

    /// Positivo si entra dinero a la cuenta, negativo si sale.
    var signedAmount: Double {
        kind == .payment ? -amount : amount
    }

    /// Borra el movimiento. Si era un pago, le regresa a la deuda lo que se le había restado.
    func remove() {
        if kind == .payment, let debt {
            debt.balance += appliedToDebt
        }
        let context = modelContext
        context?.delete(self)
        try? context?.save()
    }
}
