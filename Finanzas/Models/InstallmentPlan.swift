import Foundation
import SwiftData

/// Saldo especial dentro de una tarjeta. Los campos se reutilizan según el tipo:
/// - Compra a meses: `totalAmount` = monto de la compra, `months`, `monthlyPayment` (capturada,
///   no calculada), `startDate`. `annualRate` = 0 significa sin intereses.
/// - Transferencia de saldo: `totalAmount` = saldo actual, `annualRate` = tasa promocional,
///   `promoEndDate` = vencimiento de la promoción, `minimumPayment` = pago mínimo (opcional).
@Model
final class InstallmentPlan {
    var kindRaw: String = "installments"
    var concept: String = ""
    var totalAmount: Double = 0
    var months: Int = 12
    var monthlyPayment: Double = 0
    var annualRate: Double = 0
    var startDate: Date = Date()
    var promoEndDate: Date = Date()
    var minimumPayment: Double = 0
    var debt: Debt?

    init(kind: PlanKind) {
        self.kindRaw = kind.rawValue
    }

    var kind: PlanKind {
        get { PlanKind(rawValue: kindRaw) ?? .installments }
        set { kindRaw = newValue.rawValue }
    }

    var isInterestFree: Bool { annualRate <= 0 }

    var endDate: Date {
        switch kind {
        case .installments: return LoanMath.endDate(start: startDate, months: months)
        case .balanceTransfer: return promoEndDate
        }
    }

    func remainingMonths(asOf date: Date = Date()) -> Int {
        switch kind {
        case .installments:
            return months - LoanMath.paymentsMade(start: startDate, months: months, asOf: date)
        case .balanceTransfer:
            return LoanMath.paymentsBefore(promoEndDate, from: date)
        }
    }

    func remainingBalance(asOf date: Date = Date()) -> Double {
        switch kind {
        case .installments:
            return LoanMath.remainingBalance(
                payment: monthlyPayment,
                annualRate: annualRate,
                remainingMonths: remainingMonths(asOf: date)
            )
        case .balanceTransfer:
            return totalAmount
        }
    }

    func transferEstimate(asOf date: Date = Date()) -> TransferEstimate {
        TransferEstimate(
            balance: totalAmount,
            annualRate: annualRate,
            promoEnd: promoEndDate,
            minimumPayment: minimumPayment,
            asOf: date
        )
    }
}
