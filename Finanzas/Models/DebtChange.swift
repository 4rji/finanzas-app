import Foundation
import SwiftData

/// Cuánto subió o bajó lo que se debe en una deuda al editarla o al agregar o quitar una compra a
/// meses. Los pagos no van aquí: ya quedan como movimientos.
@Model
final class DebtChange {
    var date: Date = Date()
    var amount: Double = 0
    var debt: Debt?

    init(amount: Double, date: Date = Date()) {
        self.amount = amount
        self.date = date
    }
}
