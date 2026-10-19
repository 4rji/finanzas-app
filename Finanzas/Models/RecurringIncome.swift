import Foundation
import SwiftData

/// Ingreso que llega cada cierto tiempo, como el sueldo. En cada fecha de pago se suma solo a su
/// cuenta como un depósito (ver `RecurringDeposits`). Si tiene `fromAccount` es una transferencia
/// recurrente: en cada fecha sale de esa cuenta y entra a `account`.
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
    var fromAccount: Account?

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

    /// Entra o sale de una inversión o meta; se muestra en Inversiones y metas en lugar de Cuentas.
    var isInvestment: Bool {
        account?.kind.isSavings == true || fromAccount?.kind.isSavings == true
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
    /// Suma mensual aproximada de lo que llega de fuera (las transferencias entre cuentas no cuentan).
    var monthlyIncome: Double {
        filter { $0.fromAccount == nil }.reduce(0) { $0 + $1.monthlyAmount }
    }

    /// Suma mensual aproximada de lo que entra a inversiones y metas.
    var monthlyContributions: Double {
        filter { $0.account?.kind.isSavings == true }.reduce(0) { $0 + $1.monthlyAmount }
    }
}

/// Suma los ingresos recurrentes a su cuenta y aplica los pagos automáticos conforme llegan sus fechas.
enum RecurringDeposits {
    /// Agrega los depósitos y pagos cuya fecha ya llegó y quita duplicados. Se puede llamar las
    /// veces que sea: solo agrega lo que falta.
    static func update(in context: ModelContext, now: Date = Date()) {
        let incomes = (try? context.fetch(FetchDescriptor<RecurringIncome>())) ?? []
        let autoPayments = (try? context.fetch(FetchDescriptor<RecurringPayment>())) ?? []
        var changed = false

        for income in incomes {
            guard let account = income.account, income.amount > 0, income.fromAccount != account else { continue }
            var posted = 0
            // Tope por si la primera fecha quedó muy atrás.
            while income.nextPayDate <= now && posted < 1000 {
                // Si sale de otra cuenta es una transferencia; si no, un depósito que llega de fuera.
                let deposit = Movement(kind: income.fromAccount == nil ? .deposit : .transfer)
                context.insert(deposit)
                deposit.amount = income.amount
                deposit.date = income.nextPayDate
                deposit.payDate = income.nextPayDate
                deposit.note = income.name
                if let source = income.fromAccount {
                    deposit.account = source
                    deposit.toAccount = account
                } else {
                    deposit.account = account
                }
                deposit.income = income
                income.postedCount += 1
                posted += 1
            }
            changed = changed || posted > 0
        }

        // Para la nota del cobro del seguro, en el idioma de la app.
        let language = UserDefaults.standard.string(forKey: AppLanguage.storageKey).flatMap(AppLanguage.init(rawValue:))
        let t = L10n(language: language ?? .deviceDefault)

        for plan in autoPayments {
            guard let account = plan.account, let debt = plan.debt, plan.amount > 0 else { continue }
            var posted = 0
            while plan.nextPayDate <= now && posted < 1000 {
                // Si la deuda ya está liquidada, la fecha se salta sin cobrar. El seguro sale completo
                // de la cuenta y no toca la deuda.
                let amount = plan.isInsurance ? plan.amount : min(plan.amount, debt.payoffAmount)
                if amount > 0.005 {
                    let payment = Movement(kind: .payment)
                    context.insert(payment)
                    payment.amount = amount
                    payment.date = plan.nextPayDate
                    payment.payDate = plan.nextPayDate
                    payment.note = plan.isInsurance ? t.insuranceOf(debt.name) : debt.name
                    payment.account = account
                    payment.debt = debt
                    payment.recurringPayment = plan
                    payment.appliedToDebt = plan.isInsurance ? 0 : debt.balanceReduction(
                        forPayment: amount,
                        includesInstallments: plan.includesInstallments
                    )
                    debt.balance -= payment.appliedToDebt
                }
                plan.postedCount += 1
                posted += 1
            }
            changed = changed || posted > 0
        }

        if removeDuplicates(in: context) || changed {
            try? context.save()
        }
    }

    /// Si dos dispositivos sumaron el mismo depósito o pago antes de sincronizarse, deja solo uno.
    /// Todos eligen el mismo (el de `uuid` menor), así nunca se borran los dos. Al pago duplicado no
    /// se le regresa el monto a la deuda: los dos dispositivos guardaron el mismo saldo ya rebajado.
    private static func removeDuplicates(in context: ModelContext) -> Bool {
        let movements = (try? context.fetch(FetchDescriptor<Movement>())) ?? []
        let scheduled = movements
            .filter { $0.income != nil || $0.recurringPayment != nil }
            .sorted { $0.uuid < $1.uuid }

        var seen = Set<DepositKey>()
        var removed = false
        for movement in scheduled {
            guard let source = movement.income?.persistentModelID ?? movement.recurringPayment?.persistentModelID
            else { continue }
            let key = DepositKey(
                source: source,
                payDate: Calendar.current.startOfDay(for: movement.payDate)
            )
            if !seen.insert(key).inserted {
                context.delete(movement)
                removed = true
            }
        }
        return removed
    }

    private struct DepositKey: Hashable {
        let source: PersistentIdentifier
        let payDate: Date
    }
}
