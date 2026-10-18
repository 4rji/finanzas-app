import Foundation
import SwiftData

/// Pago automático mensual a una tarjeta o crédito: en cada fecha sale de `account` y baja la
/// deuda igual que un pago registrado a mano (ver `RecurringDeposits`).
@Model
final class RecurringPayment {
    var createdAt: Date = Date()
    var amount: Double = 0
    /// Un día de pago del que salen los siguientes, uno cada mes.
    var startDate: Date = Date()
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
        PayFrequency.monthly.payDate(postedCount, from: startDate)
    }

    /// Reinicia el calendario desde `start`. Solo se aplican los pagos de `today` en adelante.
    func reschedule(start: Date, asOf today: Date = Date()) {
        startDate = Calendar.current.startOfDay(for: start)
        postedCount = PayFrequency.monthly.firstPayIndex(onOrAfter: today, from: startDate)
    }
}
