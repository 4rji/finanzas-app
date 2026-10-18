import Foundation
import SwiftData

/// Compra a meses dentro de una tarjeta. `annualRate` = 0 significa meses sin intereses.
/// La mensualidad la captura el usuario (la del estado de cuenta), no se calcula.
@Model
final class InstallmentPlan {
    var concept: String = ""
    var totalAmount: Double = 0
    var months: Int = 12
    var monthlyPayment: Double = 0
    var annualRate: Double = 0
    var startDate: Date = Date()
    var debt: Debt?

    init(concept: String, totalAmount: Double, months: Int, monthlyPayment: Double, annualRate: Double, startDate: Date) {
        self.concept = concept
        self.totalAmount = totalAmount
        self.months = months
        self.monthlyPayment = monthlyPayment
        self.annualRate = annualRate
        self.startDate = startDate
    }

    var isInterestFree: Bool { annualRate <= 0 }

    var endDate: Date {
        LoanMath.endDate(start: startDate, months: months)
    }

    func paymentsMade(asOf date: Date = Date()) -> Int {
        LoanMath.paymentsMade(start: startDate, months: months, asOf: date)
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
