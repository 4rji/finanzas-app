import Foundation

/// Ingresos y pagos de las cuentas de cheques en el mes de `now`. "Hasta hoy" es lo que ya está en
/// el historial; el pronóstico suma además lo que falta del mes según los ingresos recurrentes y los
/// pagos automáticos. Las transferencias no cuentan: el dinero solo cambia de cuenta.
struct MonthSummary {
    /// Primer día del mes.
    let month: Date
    private(set) var income: Double = 0
    private(set) var payments: Double = 0
    private(set) var expectedIncome: Double = 0
    private(set) var expectedPayments: Double = 0

    var net: Double { income - payments }
    var expectedNet: Double { expectedIncome - expectedPayments }

    init(movements: [Movement], incomes: [RecurringIncome], autoPayments: [RecurringPayment], now: Date = Date()) {
        let interval = Calendar.current.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 0)
        month = interval.start

        for movement in movements where movement.account?.kind == .checking
            && movement.date >= interval.start && movement.date < interval.end {
            let happened = movement.date <= now
            switch movement.kind {
            case .deposit, .extra:
                expectedIncome += movement.amount
                if happened { income += movement.amount }
            case .payment:
                expectedPayments += movement.amount
                if happened { payments += movement.amount }
            case .transfer:
                break
            }
        }

        // Lo que todavía no se suma al historial: desde el siguiente pago de cada uno hasta fin de mes.
        for recurring in incomes where recurring.fromAccount == nil && recurring.account?.kind == .checking {
            let count = MonthSummary.upcomingCount(
                frequency: recurring.frequency, start: recurring.startDate, next: recurring.postedCount, in: interval
            )
            expectedIncome += recurring.amount * Double(count)
        }
        for plan in autoPayments where plan.debt != nil && plan.account?.kind == .checking {
            let count = MonthSummary.upcomingCount(
                frequency: .monthly, start: plan.startDate, next: plan.postedCount, in: interval
            )
            expectedPayments += plan.amount * Double(count)
        }
    }

    /// Fechas de pago desde el número `next` que caen dentro de `interval`.
    static func upcomingCount(frequency: PayFrequency, start: Date, next: Int, in interval: DateInterval) -> Int {
        var count = 0
        var n = next
        // Tope por si la fecha de inicio quedó muy atrás.
        while n - next < 1000 {
            let date = frequency.payDate(n, from: start)
            if date >= interval.end { break }
            if date >= interval.start { count += 1 }
            n += 1
        }
        return count
    }
}
