import Foundation

/// Cuánto falta para liquidar una deuda con el pago mensual configurado. Es aproximado.
struct PayoffEstimate {
    enum Status {
        case paidOff
        case months(Int)
        /// No hay pago mensual configurado.
        case noPayment
        /// El pago no cubre los intereses (o las mensualidades), así que nunca se liquidaría.
        case paymentTooLow
    }

    let payment: Double
    let status: Status

    var months: Int? {
        switch status {
        case .paidOff: return 0
        case .months(let n): return n
        case .noPayment, .paymentTooLow: return nil
        }
    }

    func payoffDate(from start: Date = Date()) -> Date? {
        months.map { LoanMath.endDate(start: start, months: $0) }
    }
}

/// Simulación mes a mes de una tarjeta. No usa SwiftData para poder probarla sola.
enum CardPayoff {
    struct Balance {
        var amount: Double
        /// Tasa anual mientras dure la promoción.
        var promoRate: Double
        /// Meses que le quedan a la promoción (0 si no tiene).
        var promoMonths: Int
        /// Tasa anual después de la promoción.
        var rate: Double

        func annualRate(inMonth month: Int) -> Double {
            month < promoMonths ? promoRate : rate
        }
    }

    struct Installment {
        var payment: Double
        var months: Int
    }

    /// Meses para liquidar todo pagando `payment` al mes. El pago cubre primero las mensualidades a
    /// meses y lo demás va al saldo con la tasa más alta. nil si no alcanza antes de `maxMonths`.
    static func months(balances: [Balance], installments: [Installment], payment: Double, maxMonths: Int = 600) -> Int? {
        var balances = balances
        let lastInstallment = installments.map(\.months).max() ?? 0

        for month in 0...maxMonths {
            if month >= lastInstallment && balances.allSatisfy({ $0.amount <= 0.005 }) {
                return month
            }
            let due = installments.filter { $0.months > month }.reduce(0) { $0 + $1.payment }
            var available = payment - due
            guard available > -0.005 else { return nil }

            for i in balances.indices {
                balances[i].amount += balances[i].amount * balances[i].annualRate(inMonth: month) / 100 / 12
            }
            let order = balances.indices.sorted {
                balances[$0].annualRate(inMonth: month) > balances[$1].annualRate(inMonth: month)
            }
            for i in order where available > 0 {
                let paid = min(available, balances[i].amount)
                balances[i].amount -= paid
                available -= paid
            }
        }
        return nil
    }
}

extension Debt {
    func payoffEstimate(asOf date: Date = Date()) -> PayoffEstimate {
        guard totalOwed > 0.005 else { return PayoffEstimate(payment: 0, status: .paidOff) }
        switch kind {
        case .creditCard:
            return cardPayoffEstimate(asOf: date)
        case .mortgage, .autoLoan, .studentLoan:
            guard monthlyPayment > 0 else { return PayoffEstimate(payment: 0, status: .noPayment) }
            guard !amortization.paymentTooLow else {
                return PayoffEstimate(payment: monthlyPayment, status: .paymentTooLow)
            }
            return PayoffEstimate(payment: monthlyPayment, status: .months(amortization.schedule(from: date).count))
        }
    }

    /// Las transferencias usan su tasa promocional hasta que vence y luego la tasa de la tarjeta.
    private func cardPayoffEstimate(asOf date: Date) -> PayoffEstimate {
        var balances = [CardPayoff.Balance(amount: balance, promoRate: interestRate, promoMonths: 0, rate: interestRate)]
        var installments: [CardPayoff.Installment] = []

        for plan in installmentPlans {
            switch plan.kind {
            case .installments:
                let months = plan.remainingMonths(asOf: date)
                if months > 0 {
                    installments.append(CardPayoff.Installment(payment: plan.monthlyPayment, months: months))
                }
            case .balanceTransfer:
                balances.append(CardPayoff.Balance(
                    amount: plan.totalAmount,
                    promoRate: plan.annualRate,
                    promoMonths: plan.remainingMonths(asOf: date),
                    rate: interestRate
                ))
            }
        }

        // Sin pago configurado: si solo quedan compras a meses, alcanza con las mensualidades.
        let otherBalances = balances.reduce(0) { $0 + $1.amount }
        let payment = monthlyPayment > 0 ? monthlyPayment : (otherBalances <= 0.005 ? installmentsMonthly : 0)
        guard payment > 0 else { return PayoffEstimate(payment: 0, status: .noPayment) }

        guard let months = CardPayoff.months(balances: balances, installments: installments, payment: payment) else {
            return PayoffEstimate(payment: payment, status: .paymentTooLow)
        }
        return PayoffEstimate(payment: payment, status: .months(months))
    }
}
