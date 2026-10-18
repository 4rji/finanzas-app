import Foundation
import SwiftData

/// Una deuda. Los campos se reutilizan según el tipo:
/// - Tarjeta: `balance` = deuda corriente (revolvente), `interestRate` = tasa revolvente,
///   `paymentDueDay` = día límite de pago, `plans` = compras a meses.
/// - Hipoteca / préstamo estudiantil: `balance` = saldo restante, `interestRate` = tasa anual,
///   `monthlyPayment` = pago mensual.
@Model
final class Debt {
    var name: String = ""
    var kindRaw: String = "creditCard"
    var createdAt: Date = Date()
    var balance: Double = 0
    var interestRate: Double = 0
    var monthlyPayment: Double = 0
    var paymentDueDay: Int = 1

    @Relationship(deleteRule: .cascade, inverse: \InstallmentPlan.debt)
    var plans: [InstallmentPlan]? = []

    init(name: String, kind: DebtKind) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: DebtKind {
        get { DebtKind(rawValue: kindRaw) ?? .creditCard }
        set { kindRaw = newValue.rawValue }
    }

    // MARK: Tarjeta

    var installmentPlans: [InstallmentPlan] {
        (plans ?? []).sorted { $0.startDate < $1.startDate }
    }

    var installmentsRemaining: Double {
        installmentPlans.reduce(0) { $0 + $1.remainingBalance() }
    }

    var installmentsMonthly: Double {
        installmentPlans
            .filter { $0.remainingMonths() > 0 }
            .reduce(0) { $0 + $1.monthlyPayment }
    }

    func deletePlan(_ plan: InstallmentPlan) {
        plans?.removeAll { $0.persistentModelID == plan.persistentModelID }
        modelContext?.delete(plan)
        try? modelContext?.save()
    }

    var revolvingMonthlyInterest: Double {
        balance * interestRate / 100 / 12
    }

    /// Próxima fecha límite de pago (hoy o después).
    var nextDueDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func dueDate(inMonthOf date: Date) -> Date {
            let components = calendar.dateComponents([.year, .month], from: date)
            let firstOfMonth = calendar.date(from: components) ?? date
            let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 28
            let day = min(max(paymentDueDay, 1), daysInMonth)
            return calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) ?? firstOfMonth
        }

        let thisMonth = dueDate(inMonthOf: today)
        if thisMonth >= today { return thisMonth }
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) ?? today
        return dueDate(inMonthOf: nextMonth)
    }

    // MARK: Préstamos

    var amortization: Amortization {
        Amortization(balance: balance, annualRate: interestRate, monthlyPayment: monthlyPayment)
    }

    // MARK: Total

    var totalOwed: Double {
        kind == .creditCard ? balance + installmentsRemaining : balance
    }
}
