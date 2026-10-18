import Foundation

/// Cada cuánto llega un ingreso recurrente.
enum PayFrequency: String, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case semimonthly
    case monthly

    var id: String { rawValue }

    /// Pagos promedio por mes: 52 semanas ÷ 12, 26 catorcenas ÷ 12, etc.
    var paymentsPerMonth: Double {
        switch self {
        case .weekly: return 52.0 / 12
        case .biweekly: return 26.0 / 12
        case .semimonthly: return 2
        case .monthly: return 1
        }
    }

    /// Fecha del pago número `n` (0 = `start`). Siempre se calcula desde `start` para que los
    /// fines de mes no se vayan recorriendo (31 ene → 28 feb → 31 mar).
    func payDate(_ n: Int, from start: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: start)
        switch self {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7 * n, to: start) ?? start
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14 * n, to: start) ?? start
        case .monthly:
            return calendar.date(byAdding: .month, value: n, to: start) ?? start
        case .semimonthly:
            // Dos pagos al mes con 15 días de diferencia: 15 y 30, 1 y 16, etc.
            let day = calendar.component(.day, from: start)
            let firstDay = day > 15 ? day - 15 : day
            let slot = n + (day > 15 ? 1 : 0)
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
            let month = calendar.date(byAdding: .month, value: slot / 2, to: monthStart) ?? monthStart
            let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 28
            let target = min(slot % 2 == 0 ? firstDay : firstDay + 15, daysInMonth)
            return calendar.date(byAdding: .day, value: target - 1, to: month) ?? month
        }
    }

    /// Número del primer pago que cae en `date` o después.
    func firstPayIndex(onOrAfter date: Date, from start: Date, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: date)
        var n = 0
        while payDate(n, from: start, calendar: calendar) < day && n < 100_000 {
            n += 1
        }
        return n
    }
}
