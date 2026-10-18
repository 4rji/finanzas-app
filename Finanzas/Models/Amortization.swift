import Foundation

enum LoanMath {
    /// Saldo pendiente cuando faltan `remainingMonths` pagos de `payment`.
    static func remainingBalance(payment: Double, annualRate: Double, remainingMonths: Int) -> Double {
        guard remainingMonths > 0 else { return 0 }
        let r = annualRate / 100 / 12
        guard r > 0 else { return payment * Double(remainingMonths) }
        return payment * (1 - pow(1 + r, -Double(remainingMonths))) / r
    }

    /// Mensualidades ya pagadas desde `start` (meses completos transcurridos, máximo `months`).
    static func paymentsMade(start: Date, months: Int, asOf date: Date = Date()) -> Int {
        let elapsed = Calendar.current.dateComponents([.month], from: start, to: date).month ?? 0
        return min(max(elapsed, 0), months)
    }

    static func endDate(start: Date, months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: start) ?? start
    }
}

/// Tabla de amortización aproximada a partir del saldo, la tasa y el pago mensual actuales.
struct Amortization {
    struct Row: Identifiable {
        let id: Int
        let date: Date
        let payment: Double
        let interest: Double
        let principal: Double
        let balance: Double
    }

    let balance: Double
    let annualRate: Double
    let monthlyPayment: Double

    var monthlyRate: Double { annualRate / 100 / 12 }

    var interestThisMonth: Double { balance * monthlyRate }

    var principalThisMonth: Double {
        max(min(monthlyPayment - interestThisMonth, balance), 0)
    }

    /// El pago no alcanza a cubrir los intereses: la deuda nunca se liquidaría.
    var paymentTooLow: Bool {
        balance > 0 && monthlyPayment > 0 && monthlyPayment <= interestThisMonth
    }

    func schedule(from start: Date = Date(), maxMonths: Int = 1200) -> [Row] {
        guard balance > 0, monthlyPayment > 0, !paymentTooLow else { return [] }

        let calendar = Calendar.current
        var rows: [Row] = []
        var remaining = balance
        var month = 0

        while remaining > 0.005 && month < maxMonths {
            month += 1
            let interest = remaining * monthlyRate
            let payment = min(monthlyPayment, remaining + interest)
            let principal = payment - interest
            remaining = max(remaining - principal, 0)
            let date = calendar.date(byAdding: .month, value: month, to: start) ?? start
            rows.append(Row(
                id: month,
                date: date,
                payment: payment,
                interest: interest,
                principal: principal,
                balance: remaining
            ))
        }
        return rows
    }
}
