import Foundation
import SwiftData

/// Compra a meses dentro de una tarjeta. `annualRate` = 0 significa meses sin intereses.
@Model
final class InstallmentPlan {
    var concept: String = ""
    var totalAmount: Double = 0
    var months: Int = 12
    var annualRate: Double = 0
    var startDate: Date = Date()
    var debt: Debt?

    init(concept: String, totalAmount: Double, months: Int, annualRate: Double, startDate: Date) {
        self.concept = concept
        self.totalAmount = totalAmount
        self.months = months
        self.annualRate = annualRate
        self.startDate = startDate
    }

    var isInterestFree: Bool { annualRate <= 0 }

    var monthlyPayment: Double {
        LoanMath.payment(principal: totalAmount, annualRate: annualRate, months: months)
    }

    var endDate: Date {
        LoanMath.endDate(start: startDate, months: months)
    }

    func paymentsMade(asOf date: Date = Date()) -> Int {
        let elapsed = Calendar.current.dateComponents([.month], from: startDate, to: date).month ?? 0
        return min(max(elapsed, 0), months)
    }

    func remainingMonths(asOf date: Date = Date()) -> Int {
        months - paymentsMade(asOf: date)
    }

    func remainingBalance(asOf date: Date = Date()) -> Double {
        LoanMath.remainingBalance(
            payment: monthlyPayment,
            annualRate: annualRate,
            remainingMonths: remainingMonths(asOf: date)
        )
    }
}
