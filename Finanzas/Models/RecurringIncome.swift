import Foundation
import SwiftData

/// Ingreso que llega cada cierto tiempo, como el sueldo. En cada fecha de pago se suma solo a su
/// cuenta como un depósito (ver `RecurringDeposits`).
@Model
final class RecurringIncome {
    var name: String = ""
    var createdAt: Date = Date()
    var amount: Double = 0
    var frequencyRaw: String = "weekly"
    /// Un día de pago (pasado o futuro) del que salen las demás fechas según la frecuencia.
    var startDate: Date = Date()
    /// Número del siguiente pago por sumar, contando desde `startDate`.
    var postedCount: Int = 0
    var account: Account?

    @Relationship(deleteRule: .nullify, inverse: \Movement.income)
    var deposits: [Movement]? = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }

    var frequency: PayFrequency {
        get { PayFrequency(rawValue: frequencyRaw) ?? .weekly }
        set { frequencyRaw = newValue.rawValue }
    }

    var nextPayDate: Date {
        frequency.payDate(postedCount, from: startDate)
    }

    /// Equivalente mensual aproximado.
    var monthlyAmount: Double {
        amount * frequency.paymentsPerMonth
    }

    /// Reinicia el calendario desde `start`. Solo se suman los pagos de `today` en adelante:
    /// los anteriores ya deberían estar en el saldo de la cuenta.
    func reschedule(start: Date, frequency: PayFrequency, asOf today: Date = Date()) {
        self.frequency = frequency
        startDate = Calendar.current.startOfDay(for: start)
        postedCount = frequency.firstPayIndex(onOrAfter: today, from: startDate)
    }
}

extension Sequence where Element == RecurringIncome {
    /// Suma mensual aproximada.
    var monthlyIncome: Double {
        reduce(0) { $0 + $1.monthlyAmount }
    }
}

/// Suma los ingresos recurrentes a su cuenta conforme llegan sus fechas de pago.
enum RecurringDeposits {
    /// Agrega los depósitos cuya fecha ya llegó y quita duplicados. Se puede llamar las veces que
    /// sea: solo agrega lo que falta.
    static func update(in context: ModelContext, now: Date = Date()) {
        let incomes = (try? context.fetch(FetchDescriptor<RecurringIncome>())) ?? []
        var changed = false

        for income in incomes {
            guard let account = income.account, income.amount > 0 else { continue }
            var posted = 0
            // Tope por si la primera fecha quedó muy atrás.
            while income.nextPayDate <= now && posted < 1000 {
                let deposit = Movement(kind: .deposit)
                context.insert(deposit)
                deposit.amount = income.amount
                deposit.date = income.nextPayDate
                deposit.payDate = income.nextPayDate
                deposit.note = income.name
                deposit.account = account
                deposit.income = income
                income.postedCount += 1
                posted += 1
            }
            changed = changed || posted > 0
        }

        if removeDuplicates(in: context) || changed {
            try? context.save()
        }
    }

    /// Si dos dispositivos sumaron el mismo depósito antes de sincronizarse, deja solo uno.
    /// Todos eligen el mismo (el de `uuid` menor), así nunca se borran los dos.
    private static func removeDuplicates(in context: ModelContext) -> Bool {
        let movements = (try? context.fetch(FetchDescriptor<Movement>())) ?? []
        let deposits = movements
            .filter { $0.kind == .deposit && $0.income != nil }
            .sorted { $0.uuid < $1.uuid }

        var seen = Set<DepositKey>()
        var removed = false
        for deposit in deposits {
            guard let income = deposit.income else { continue }
            let key = DepositKey(
                income: income.persistentModelID,
                payDate: Calendar.current.startOfDay(for: deposit.payDate)
            )
            if !seen.insert(key).inserted {
                context.delete(deposit)
                removed = true
            }
        }
        return removed
    }

    private struct DepositKey: Hashable {
        let income: PersistentIdentifier
        let payDate: Date
    }
}
