import Foundation
import SwiftData

/// Pago automático a una tarjeta o crédito: en cada fecha sale de `account` y baja la deuda igual
/// que un pago registrado a mano (ver `RecurringDeposits`). Si es el seguro del préstamo, sale de la
/// cuenta pero no baja la deuda.
@Model
final class RecurringPayment {
    var createdAt: Date = Date()
    var amount: Double = 0
    /// Un día de pago del que salen los siguientes, uno cada `intervalMonths`.
    var startDate: Date = Date()
    /// Meses entre un pago y el siguiente: 1 en el pago de la deuda; 1, 6 o 12 en el seguro.
    var intervalMonths: Int = 1
    var isInsurance: Bool = false
    /// Número del siguiente pago por aplicar, contando desde `startDate`.
    var postedCount: Int = 0
    /// Solo tarjetas: el pago cubre primero las mensualidades a meses (ver `Debt.balanceReduction`).
    var includesInstallments: Bool = true
    var account: Account?
    var debt: Debt?

    @Relationship(deleteRule: .nullify, inverse: \Movement.recurringPayment)
    var payments: [Movement]? = []

    init() {
        self.createdAt = Date()
    }

    var nextPayDate: Date {
        payDate(postedCount)
    }

    /// Fecha del pago número `n` (0 = `startDate`).
    func payDate(_ n: Int) -> Date {
        PayFrequency.monthly.payDate(n * max(intervalMonths, 1), from: startDate)
    }

    /// Reinicia el calendario desde `start`. Solo se aplican los pagos de `today` en adelante.
    func reschedule(start: Date, asOf today: Date = Date()) {
        startDate = Calendar.current.startOfDay(for: start)
        let day = Calendar.current.startOfDay(for: today)
        postedCount = 0
        while payDate(postedCount) < day && postedCount < 100_000 {
            postedCount += 1
        }
    }
}
