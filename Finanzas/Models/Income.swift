import Foundation
import SwiftData

/// Un ingreso. Los campos se reutilizan según el tipo:
/// - Recurrente: `amount` = lo que depositan cada vez, `frequencyRaw` = cada cuánto.
/// - Extra: `amount` = monto recibido una sola vez, `date` = cuándo llegó. No cambia los recurrentes.
@Model
final class Income {
    var name: String = ""
    var kindRaw: String = "recurring"
    var createdAt: Date = Date()
    var amount: Double = 0
    var frequencyRaw: String = "weekly"
    var date: Date = Date()

    init(name: String, kind: IncomeKind) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: IncomeKind {
        get { IncomeKind(rawValue: kindRaw) ?? .recurring }
        set { kindRaw = newValue.rawValue }
    }

    var frequency: PayFrequency {
        get { PayFrequency(rawValue: frequencyRaw) ?? .weekly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Equivalente mensual aproximado de un ingreso recurrente; 0 para extras.
    var monthlyAmount: Double {
        kind == .recurring ? amount * frequency.paymentsPerMonth : 0
    }
}

extension Sequence where Element == Income {
    /// Suma mensual aproximada de los ingresos recurrentes.
    var monthlyIncome: Double {
        reduce(0) { $0 + $1.monthlyAmount }
    }

    /// Suma de los ingresos extra recibidos en el mes de `date`.
    func extrasTotal(inMonthOf date: Date = Date()) -> Double {
        filter { $0.kind == .extra && Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}
