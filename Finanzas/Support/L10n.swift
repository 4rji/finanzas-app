import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"

    static let storageKey = "appLanguage"

    static var deviceDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("es") == true ? .spanish : .english
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    /// Idioma elegido + región del dispositivo (para moneda y formato de números).
    var locale: Locale {
        let region = Locale.current.region?.identifier ?? (self == .spanish ? "MX" : "US")
        return Locale(identifier: "\(rawValue)_\(region)")
    }
}

/// Textos de la app en inglés y español.
struct L10n {
    let language: AppLanguage

    var locale: Locale { language.locale }
    private var isSpanish: Bool { language == .spanish }
    private func pick(_ en: String, _ es: String) -> String { isSpanish ? es : en }

    // MARK: General

    var appName: String { "Finanzas" }
    var debts: String { pick("Debts", "Deudas") }
    var totalDebt: String { pick("Total debt", "Deuda total") }
    var add: String { pick("Add", "Agregar") }
    var save: String { pick("Save", "Guardar") }
    var cancel: String { pick("Cancel", "Cancelar") }
    var edit: String { pick("Edit", "Editar") }
    var delete: String { pick("Delete", "Eliminar") }
    var done: String { pick("Done", "Listo") }
    var settings: String { pick("Settings", "Configuración") }
    var languageTitle: String { pick("Language", "Idioma") }
    var textSizeTitle: String { pick("Text size", "Tamaño de letra") }

    func textSizeName(_ size: TextSize) -> String {
        switch size {
        case .normal: return "Normal"
        case .large: return pick("Large", "Grande")
        case .extraLarge: return pick("Extra large", "Muy grande")
        }
    }
    var summary: String { pick("Summary", "Resumen") }
    var name: String { pick("Name", "Nombre") }

    func debtCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 deuda" : "\(n) deudas" }
        return n == 1 ? "1 debt" : "\(n) debts"
    }

    // MARK: Lista de deudas

    var noDebtsTitle: String { pick("No debts yet", "Aún no hay deudas") }
    var noDebtsMessage: String {
        pick("Use the + button to add a credit card, mortgage or student loan.",
             "Usa el botón + para agregar una tarjeta, hipoteca o préstamo estudiantil.")
    }

    func kindName(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("Credit card", "Tarjeta de crédito")
        case .mortgage: return pick("Mortgage", "Hipoteca")
        case .studentLoan: return pick("Student loan", "Préstamo estudiantil")
        }
    }

    func kindPlural(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("Credit cards", "Tarjetas de crédito")
        case .mortgage: return pick("Mortgages", "Hipotecas")
        case .studentLoan: return pick("Student loans", "Préstamos estudiantiles")
        }
    }

    func namePlaceholder(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("e.g. Visa Gold", "ej. Visa Oro")
        case .mortgage: return pick("e.g. House", "ej. Casa")
        case .studentLoan: return pick("e.g. University", "ej. Universidad")
        }
    }

    // MARK: Tarjeta

    var creditLimit: String { pick("Credit limit", "Límite de crédito") }
    var creditUsed: String { pick("Credit used", "Crédito usado") }
    var availableCredit: String { pick("Available credit", "Crédito disponible") }

    /// "45%" a partir de una fracción (0.45).
    func usage(_ fraction: Double) -> String {
        (fraction * 100).formatted(.number.precision(.fractionLength(0)).locale(locale)) + "%"
    }

    func usageUsed(_ fraction: Double) -> String {
        usage(fraction) + pick(" used", " usado")
    }

    func creditUsedShort(_ fraction: Double) -> String {
        usage(fraction) + pick(" of credit used", " de crédito usado")
    }

    func amountOf(_ used: Double, _ limit: Double) -> String {
        money(used) + pick(" of ", " de ") + money(limit)
    }

    var paymentDueDay: String { pick("Payment due day", "Día límite de pago") }
    var nextDueDate: String { pick("Next due date", "Próximo vencimiento") }
    var dueShort: String { pick("Due", "Vence") }
    var revolvingSection: String { pick("Revolving balance", "Saldo revolvente") }
    var currentBalance: String { pick("Current balance", "Deuda corriente") }
    var interestRateApprox: String { pick("Annual interest rate (approx.)", "Tasa de interés anual (aprox.)") }
    var monthlyInterestApprox: String { pick("Approx. monthly interest", "Interés mensual aprox.") }
    var cardFormFooter: String {
        pick("Revolving part only. Installment plans are managed from the card's detail.",
             "Solo la parte revolvente. Las compras a meses se manejan en el detalle de la tarjeta.")
    }

    var balanceSection: String { pick("Balance", "Saldo") }
    var balanceTypeQuestion: String { pick("How is the balance?", "¿Cómo está el saldo?") }
    var balanceTypeFooter: String {
        pick("Only the revolving balance accrues interest. Installments and balance transfers are tracked separately so they aren't counted twice.",
             "Solo el saldo revolvente genera intereses. Las compras a meses y transferencias se registran aparte para no sumarlas dos veces.")
    }
    var includedInBalance: String { pick("Already included in revolving balance", "Ya está incluida en el saldo revolvente") }
    var includedInBalanceFooter: String {
        pick("Turn on if the revolving balance you entered already includes this purchase. It will be subtracted from there so it isn't counted twice.",
             "Actívalo si el saldo revolvente que capturaste ya incluye esta compra; se restará de ahí para no contarla dos veces.")
    }

    func balanceTypeName(_ type: CardBalanceType) -> String {
        switch type {
        case .revolving: return pick("Revolving", "Revolvente")
        case .installments: return pick("Balance transfer or installments", "Transferencia o a meses")
        case .both: return pick("Both", "Ambos")
        }
    }

    var installmentsSection: String { pick("Installments & balance transfers", "Compras a meses y transferencias") }
    var noInstallments: String { pick("No installment plans or transfers", "Sin compras a meses ni transferencias") }
    var addInstallment: String { pick("Add installment plan or transfer", "Agregar compra a meses o transferencia") }
    var planType: String { pick("Type", "Tipo") }
    var descriptionOptional: String { pick("Description (optional)", "Descripción (opcional)") }
    var conceptPlaceholder: String { pick("e.g. Laptop", "ej. Laptop") }
    var transferPlaceholder: String { pick("e.g. From Visa", "ej. Desde Visa") }

    func planKindName(_ kind: PlanKind) -> String {
        switch kind {
        case .installments: return pick("Installment plan", "Compra a meses")
        case .balanceTransfer: return pick("Balance transfer", "Transferencia de saldo")
        }
    }

    // Transferencia de saldo
    var transferBalance: String { pick("Transfer balance", "Saldo de la transferencia") }
    var promoRate: String { pick("Promo rate", "Tasa promocional") }
    var promoEndDate: String { pick("Promo end date", "Vencimiento de la promoción") }
    var minimumPaymentOptional: String { pick("Minimum payment (optional)", "Pago mínimo (opcional)") }
    var minimumShort: String { pick("Minimum", "Mínimo") }
    var transferFeeOptional: String { pick("Transfer fee (optional)", "Comisión por transferencia (opcional)") }
    var transferFee: String { pick("Transfer fee", "Comisión por transferencia") }

    func feeShort(percent value: Double, amount: Double) -> String {
        pick("Fee ", "Comisión ") + percent(value) + " · " + money(amount)
    }
    var timeLeft: String { pick("Time left", "Tiempo restante") }
    var suggestedPayment: String { pick("Suggested payment (approx.)", "Pago sugerido (aprox.)") }
    var promoExpired: String { pick("Promo expired", "Promoción vencida") }
    var transferFooter: String {
        pick("The suggested payment is only an approximate reference to pay off the balance before the promo ends. It isn't required.",
             "El pago sugerido es solo una referencia aproximada para liquidar antes del vencimiento. No es obligatorio.")
    }

    func suggestedShort(_ value: Double) -> String {
        pick("Suggested: ", "Sugerido: ") + perMonth(value)
    }

    func leftoverPayingMinimum(_ value: Double) -> String {
        isSpanish
            ? "Pagando solo el mínimo quedarían \(money(value)) al vencimiento"
            : "Paying only the minimum leaves \(money(value)) when the promo ends"
    }

    func monthsLeftShort(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "falta 1 mes" : "faltan \(n) meses" }
        return n == 1 ? "1 month left" : "\(n) months left"
    }
    var totalAmount: String { pick("Total amount", "Monto total") }
    var annualRate: String { pick("Annual interest rate", "Tasa de interés anual") }
    var startDate: String { pick("Start date", "Fecha de inicio") }
    var endsOn: String { pick("Ends", "Termina") }
    var interestFree: String { pick("Interest-free", "Sin intereses") }
    var paidOff: String { pick("Paid off", "Liquidado") }
    var monthlyPayment: String { pick("Monthly payment", "Pago mensual") }
    var planRateFooter: String {
        pick("Leave the rate at 0 for interest-free installments.",
             "Deja la tasa en 0 para meses sin intereses.")
    }

    func installmentsFooter(balance: Double, monthly: Double) -> String {
        isSpanish
            ? "Saldo a meses: \(money(balance)) · Mensualidades: \(money(monthly))"
            : "Installments balance: \(money(balance)) · Monthly: \(money(monthly))"
    }

    func perMonth(_ value: Double) -> String {
        money(value) + pick("/mo", "/mes")
    }

    func monthsLeft(_ remaining: Int, of total: Int) -> String {
        if isSpanish {
            return remaining == 1 ? "Falta 1 de \(total) meses" : "Faltan \(remaining) de \(total) meses"
        }
        return "\(remaining) of \(total) months left"
    }

    func monthsCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 mes" : "\(n) meses" }
        return n == 1 ? "1 month" : "\(n) months"
    }

    func yearsCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 año" : "\(n) años" }
        return n == 1 ? "1 year" : "\(n) years"
    }

    func duration(months n: Int) -> String {
        let years = n / 12
        let rest = n % 12
        if years == 0 { return monthsCount(rest) }
        if rest == 0 { return yearsCount(years) }
        return yearsCount(years) + ", " + monthsCount(rest)
    }

    // MARK: Préstamos

    var remainingBalance: String { pick("Remaining balance", "Saldo restante") }
    var estimateSection: String { pick("Approximate estimate", "Estimación aproximada") }
    var monthlyInterestFooter: String {
        pick("Balance × rate ÷ 12. It goes down a little each month as the balance drops.",
             "Saldo × tasa ÷ 12. Baja un poco cada mes conforme baja el saldo.")
    }

    func interestShort(_ value: Double) -> String {
        pick("Interest ", "Interés ") + perMonth(value)
    }
    var principalThisMonth: String { pick("Principal this month", "Abono a capital este mes") }
    var timeToPayoff: String { pick("Time to pay off", "Tiempo para liquidar") }
    var payoffDate: String { pick("Estimated payoff date", "Fecha estimada de liquidación") }
    var totalInterestRemaining: String { pick("Total interest remaining", "Interés total restante") }
    var amortizationTable: String { pick("Amortization table", "Tabla de amortización") }
    var approxNote: String {
        pick("Approximate values. Your payment may include insurance, taxes or other fees, so real numbers may differ.",
             "Valores aproximados. Tu pago puede incluir seguros, impuestos u otros gastos, así que las cifras reales pueden variar.")
    }
    var paymentTooLow: String {
        pick("The monthly payment doesn't cover the interest, so the debt would never be paid off.",
             "El pago mensual no cubre los intereses, así que la deuda nunca se liquidaría.")
    }

    var tableMonth: String { pick("Month", "Mes") }
    var payment: String { pick("Payment", "Pago") }
    var interest: String { pick("Interest", "Interés") }
    var principal: String { pick("Principal", "Capital") }
    var balance: String { pick("Balance", "Saldo") }

    // MARK: Ingresos

    var income: String { pick("Income", "Ingresos") }
    var noIncomeTitle: String { pick("No income yet", "Aún no hay ingresos") }
    var noIncomeMessage: String {
        pick("Use the + button to add your salary or an extra income.",
             "Usa el botón + para agregar tu sueldo o un ingreso extra.")
    }
    var monthlyIncome: String { pick("Monthly income (approx.)", "Ingreso mensual (aprox.)") }
    var perMonthApprox: String { pick("Per month, approx.", "Al mes, aprox.") }
    var extrasThisMonth: String { pick("Extras this month", "Extras este mes") }
    var amount: String { pick("Amount", "Monto") }
    var amountPerPayment: String { pick("Amount per deposit", "Monto por depósito") }
    var howOften: String { pick("How often", "Cada cuánto") }
    var dateReceived: String { pick("Date received", "Fecha en que lo recibiste") }
    var recurringIncomeFooter: String {
        pick("What you get each time. Extra income is added separately and doesn't change this amount.",
             "Lo que te depositan cada vez. Los ingresos extra se agregan aparte y no cambian este monto.")
    }
    var extraIncomeFooter: String {
        pick("One-time income, like a bonus or a sale. It doesn't change your recurring income.",
             "Ingreso de una sola vez, como un bono o una venta. No cambia tu ingreso recurrente.")
    }

    func incomeKindName(_ kind: IncomeKind) -> String {
        switch kind {
        case .recurring: return pick("Recurring income", "Ingreso recurrente")
        case .extra: return pick("Extra income", "Ingreso extra")
        }
    }

    func incomeKindPlural(_ kind: IncomeKind) -> String {
        switch kind {
        case .recurring: return pick("Recurring", "Recurrentes")
        case .extra: return "Extras"
        }
    }

    func incomeNamePlaceholder(_ kind: IncomeKind) -> String {
        switch kind {
        case .recurring: return pick("e.g. Salary", "ej. Sueldo")
        case .extra: return pick("e.g. Bonus", "ej. Bono")
        }
    }

    func frequencyName(_ frequency: PayFrequency) -> String {
        switch frequency {
        case .weekly: return pick("Every week", "Cada semana")
        case .biweekly: return pick("Every 2 weeks", "Cada dos semanas")
        case .semimonthly: return pick("Twice a month", "Dos veces al mes")
        case .monthly: return pick("Every month", "Cada mes")
        }
    }

    func approxPerMonth(_ value: Double) -> String {
        "≈ " + perMonth(value)
    }

    // MARK: Calendario

    var dayTitle: String { pick("Day", "Día") }
    var monthTitle: String { pick("Month", "Mes") }
    var yearTitle: String { pick("Year", "Año") }

    /// "Jan", "Feb"… o "Ene", "Feb"… según el idioma.
    var shortMonthNames: [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.shortStandaloneMonthSymbols.map { name in
            String(name.replacingOccurrences(of: ".", with: "").prefix(3)).capitalized(with: locale)
        }
    }

    // MARK: Formato

    var currencyCode: String { Locale.current.currency?.identifier ?? "USD" }
    var currencySymbol: String { Locale.current.currencySymbol ?? "$" }

    func money(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode).locale(locale))
    }

    func moneyWhole(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(locale))
    }

    func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(locale)) + "%"
    }

    func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }

    func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    func monthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }
}

// MARK: - Environment

private struct L10nKey: EnvironmentKey {
    static let defaultValue = L10n(language: .deviceDefault)
}

extension EnvironmentValues {
    var l10n: L10n {
        get { self[L10nKey.self] }
        set { self[L10nKey.self] = newValue }
    }
}
