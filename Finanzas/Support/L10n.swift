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
    /// Saldos ocultos con el botón del ojo: todos los montos se muestran como asteriscos.
    var hidesAmounts = false

    static let hidesAmountsKey = "hidesAmounts"

    var locale: Locale { language.locale }
    private var isSpanish: Bool { language == .spanish }
    private func pick(_ en: String, _ es: String) -> String { isSpanish ? es : en }

    // MARK: General

    var appName: String { "Finanzas" }
    var debts: String { pick("Debts", "Deudas") }
    var investments: String { pick("Investments & goals", "Inversiones y metas") }
    var assets: String { pick("Property", "Bienes") }
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
    var appearanceTitle: String { pick("Appearance", "Apariencia") }

    func appearanceName(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: return pick("System", "Sistema")
        case .light: return pick("Light", "Claro")
        case .dark: return pick("Dark", "Oscuro")
        }
    }

    var hideAmounts: String { pick("Hide amounts", "Ocultar saldos") }
    var showAmounts: String { pick("Show amounts", "Mostrar saldos") }
    var homeSettingsTitle: String { pick("Home screen", "Pantalla de inicio") }
    var homeSettingsMessage: String {
        pick("Drag to reorder the sections. Turn them on or off to show or hide them on the home screen.",
             "Arrastra para cambiar el orden. Activa o desactiva cada sección para mostrarla u ocultarla en inicio.")
    }
    var generalTitle: String { pick("General", "General") }
    var languageHint: String { pick("App text", "Textos de la app") }
    var textSizeHint: String { pick("Throughout the app", "En toda la app") }
    var appearanceHint: String { pick("Light, dark or like the system", "Claro, oscuro o como el sistema") }
    var hideAmountsHint: String { pick("Shows ***** instead of amounts", "Muestra ***** en lugar de los montos") }
    var shownOnHome: String { pick("Shown on home", "Se muestra en inicio") }
    var hiddenFromHome: String { pick("Hidden", "Oculta") }
    var close: String { pick("Close", "Cerrar") }
    var showAsGrid: String { pick("Grid", "Cuadrícula") }
    var showAsCarousel: String { pick("Carousel", "Carrusel") }
    var financialOverview: String { pick("Your money at a glance", "Tu dinero, de un vistazo") }
    var previousSection: String { pick("Previous section", "Sección anterior") }
    var nextSection: String { pick("Next section", "Siguiente sección") }

    func carouselPosition(_ position: Int, total: Int) -> String {
        pick("Section \(position) of \(total)", "Sección \(position) de \(total)")
    }

    /// Nombres breves para que las cuatro pestañas sigan siendo legibles en pantallas pequeñas.
    func homeSectionTabName(_ section: HomeSection) -> String {
        section == .investments ? pick("Investments", "Inversiones") : homeSectionName(section)
    }

    func homeSectionName(_ section: HomeSection) -> String {
        switch section {
        case .accounts: return accounts
        case .investments: return investments
        case .debts: return debts
        case .assets: return assets
        }
    }
    var everythingHidden: String { pick("Everything is hidden", "Todo está oculto") }
    var everythingHiddenMessage: String {
        pick("Turn the categories back on in Settings.", "Vuelve a mostrar las categorías en Configuración.")
    }

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
        pick("Use the + button to add a credit card, mortgage, auto loan or student loan.",
             "Usa el botón + para agregar una tarjeta, hipoteca, préstamo de auto o préstamo estudiantil.")
    }
    var excludeFromTotal: String { pick("Leave out of total", "Excluir del total") }
    var includeInTotal: String { pick("Count in total", "Incluir en el total") }
    var excludedFromTotal: String { pick("Not in total", "Fuera del total") }
    var excludedFromTotalFooter: String {
        pick("These debts don't count toward the total debt.", "Estas deudas no se suman a la deuda total.")
    }

    func kindName(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("Credit card", "Tarjeta de crédito")
        case .mortgage: return pick("Mortgage", "Hipoteca")
        case .autoLoan: return pick("Auto loan", "Préstamo de auto")
        case .studentLoan: return pick("Student loan", "Préstamo estudiantil")
        }
    }

    func kindPlural(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("Credit cards", "Tarjetas de crédito")
        case .mortgage: return pick("Mortgages", "Hipotecas")
        case .autoLoan: return pick("Auto loans", "Préstamos de auto")
        case .studentLoan: return pick("Student loans", "Préstamos estudiantiles")
        }
    }

    func namePlaceholder(_ kind: DebtKind) -> String {
        switch kind {
        case .creditCard: return pick("e.g. Visa Gold", "ej. Visa Oro")
        case .mortgage: return pick("e.g. House", "ej. Casa")
        case .autoLoan: return pick("e.g. Car", "ej. Auto")
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
    var cardPlannedPayment: String { pick("Monthly payment you make (optional)", "Pago mensual que haces (opcional)") }
    var cardPlannedPaymentFooter: String {
        pick("The monthly payment is used to estimate when you'll pay off the card. Include installment payments.",
             "El pago mensual sirve para estimar cuándo terminas de pagar la tarjeta. Incluye las mensualidades a meses.")
    }
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

    // Seguro del auto
    var insurance: String { pick("Insurance", "Seguro") }
    var insuranceAmount: String { pick("Insurance payment", "Pago del seguro") }
    var insuranceFooter: String {
        pick("Just a note so you know how much it is. It doesn't change the loan payment or the total.",
             "Solo es una nota para saber cuánto es. No cambia el pago del préstamo ni el total.")
    }

    func insuranceNote(_ value: Double) -> String {
        pick("Insurance ", "Seguro ") + money(value) + pick(" (note)", " (nota)")
    }

    // Tiempo para liquidar
    var payoffQuestion: String { pick("When will I pay off my debts?", "¿Cuándo termino de pagar?") }
    var payoffHint: String {
        pick("Each debt with its payment, balance and time left", "Cada deuda con su pago, saldo y tiempo que falta")
    }
    var monthlyPayments: String { pick("Monthly payments", "Pagos mensuales") }
    var debtFreeApprox: String { pick("Debt-free (approx.)", "Sin deudas (aprox.)") }
    var payoffFooter: String {
        pick("Approximate, with each debt's monthly payment and rate. On cards the payment covers installments first and then the balance with the highest rate; when a promo ends, the card's rate is used.",
             "Aproximado, con el pago mensual y la tasa de cada deuda. En tarjetas el pago cubre primero las mensualidades a meses y luego el saldo con la tasa más alta; al vencer una promoción se usa la tasa de la tarjeta.")
    }
    var noPaymentSet: String { pick("No monthly payment set. Add it in Edit.", "Sin pago mensual. Agrégalo en Editar.") }
    var paymentNotEnough: String { pick("The payment isn't enough to pay it off.", "El pago no alcanza para liquidarla.") }

    func paymentShort(_ value: Double) -> String {
        pick("Payment ", "Pago ") + perMonth(value)
    }

    func payoffIn(months: Int, date: Date) -> String {
        isSpanish
            ? "Se liquida en \(duration(months: months)) (\(monthYear(date)))"
            : "Paid off in \(duration(months: months)) (\(monthYear(date)))"
    }

    func promoEnds(_ date: Date) -> String {
        pick("Promo ends ", "La promoción vence el ") + self.date(date)
    }

    var tableMonth: String { pick("Month", "Mes") }
    var payment: String { pick("Payment", "Pago") }
    var interest: String { pick("Interest", "Interés") }
    var principal: String { pick("Principal", "Capital") }
    var balance: String { pick("Balance", "Saldo") }

    // MARK: Cuentas e ingresos

    var accounts: String { pick("Accounts", "Cuentas") }
    var account: String { pick("Account", "Cuenta") }
    var history: String { pick("History", "Historial") }
    var noAccountsTitle: String { pick("No accounts yet", "Aún no hay cuentas") }
    var noAccountsMessage: String {
        pick("Add your checking account with its current balance. Deposits and payments will keep it up to date.",
             "Agrega tu cuenta de cheques con su saldo actual. Los depósitos y pagos lo irán actualizando.")
    }
    var addAccount: String { pick("Add account", "Agregar cuenta") }
    var addAccountHint: String { pick("Add your checking account", "Agrega tu cuenta de cheques") }
    var accountNamePlaceholder: String { pick("e.g. Checking", "ej. Cheques") }
    var accountBalance: String { pick("Current balance", "Saldo actual") }
    var accountFooter: String {
        pick("Enter what you have today. Deposits, extra income and payments update it.",
             "Escribe lo que tienes hoy. Los depósitos, ingresos extra y pagos lo van actualizando.")
    }
    var accountDeleteNote: String {
        pick("Deleting the account also deletes its history and recurring income.",
             "Eliminar la cuenta también borra su historial y sus ingresos recurrentes.")
    }
    var totalBalance: String { pick("Total balance", "Saldo total") }

    // Inversiones
    var investment: String { pick("Investment", "Inversión") }
    var investmentsSection: String { pick("Investments", "Inversiones") }
    var noInvestmentsTitle: String { pick("No investments or goals yet", "Aún no hay inversiones ni metas") }
    var noInvestmentsMessage: String {
        pick("Add an investment like a 401(k), FSA or stocks, or a goal to save toward, like a vacation.",
             "Agrega una inversión como 401(k), FSA o acciones, o una meta para ir ahorrando, como unas vacaciones.")
    }
    var addInvestment: String { pick("Add investment", "Agregar inversión") }
    var addInvestmentHint: String { pick("Add a 401(k), stocks or a savings goal", "Agrega 401(k), acciones o una meta de ahorro") }
    var investmentNamePlaceholder: String { pick("e.g. FSA, Stocks", "ej. FSA, Acciones") }
    var investmentValue: String { pick("Current value", "Valor actual") }
    var investmentFooter: String {
        pick("Enter what it's worth today. Transfers and contributions update it.",
             "Escribe cuánto vale hoy. Las transferencias y aportes lo van actualizando.")
    }
    var totalValue: String { pick("Total value", "Valor total") }

    func investmentCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 inversión" : "\(n) inversiones" }
        return n == 1 ? "1 investment" : "\(n) investments"
    }

    var contribution: String { pick("Contribution", "Aporte") }
    var recurringContribution: String { pick("Recurring contribution", "Aporte recurrente") }
    var recurringContributions: String { pick("Recurring contributions", "Aportes recurrentes") }
    var addRecurringContribution: String { pick("Add recurring contribution", "Agregar aporte recurrente") }
    var noRecurringContributions: String { pick("No recurring contributions", "Sin aportes recurrentes") }
    var monthlyAmountApprox: String { pick("Per month (approx.)", "Al mes (aprox.)") }
    var investmentsHistoryHint: String {
        pick("Transfers and contributions are listed in Accounts → History.",
             "Las transferencias y aportes se ven en Cuentas → Historial.")
    }

    // Metas
    var goal: String { pick("Goal", "Meta") }
    var goals: String { pick("Goals", "Metas") }
    var addGoal: String { pick("Add goal", "Agregar meta") }
    var typeTitle: String { pick("Type", "Tipo") }
    var goalNamePlaceholder: String { pick("e.g. Vacation, Emergency fund", "ej. Vacaciones, Fondo de emergencia") }
    var goalAmount: String { pick("How much you want to save", "¿Cuánto quieres juntar?") }
    var savedSoFar: String { pick("Saved so far", "Ahorrado hasta hoy") }
    var goalReached: String { pick("Goal reached!", "¡Meta cumplida!") }
    var goalFooter: String {
        pick("Save toward it with Move money or a recurring contribution. It can be a savings account or an investment, whatever you prefer.",
             "Ve juntando con Mover dinero o con un aporte recurrente. Puede ser una cuenta de ahorro o una inversión, como prefieras.")
    }

    func goalLeft(_ value: Double) -> String {
        pick("", "Faltan ") + money(value) + pick(" to go", "")
    }

    func goalCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 meta" : "\(n) metas" }
        return n == 1 ? "1 goal" : "\(n) goals"
    }

    func savingsKindName(_ kind: AccountKind) -> String {
        switch kind {
        case .checking: return account
        case .investment: return investment
        case .goal: return goal
        }
    }

    func contributionsPerMonthShort(_ value: Double) -> String {
        pick("Contributions ", "Aportes ") + approxPerMonth(value)
    }

    // Mover dinero
    var transfer: String { pick("Transfer", "Transferencia") }
    var moveMoney: String { pick("Move money", "Mover dinero") }
    var fromLabel: String { pick("From", "Desde") }
    var toLabel: String { pick("To", "Hacia") }
    var outsideSource: String { pick("Somewhere else (e.g. salary)", "Otro lugar (ej. sueldo)") }
    var outsideShort: String { pick("Elsewhere", "Otro lugar") }
    var repeats: String { pick("Repeats", "Se repite") }
    var moveNotePlaceholder: String { pick("e.g. Savings", "ej. Ahorro") }
    var moveMoneyFooter: String {
        pick("Moves money between your accounts and investments. If it comes from somewhere else, like your salary, it's only added to the destination.",
             "Mueve dinero entre tus cuentas e inversiones. Si viene de otro lugar, como tu sueldo, solo se suma al destino.")
    }
    var moveRecurringFooter: String {
        pick("It's applied automatically on each date, starting with the next one.",
             "Se aplica solo en cada fecha, desde la próxima.")
    }

    func balanceAfter(_ name: String) -> String {
        isSpanish ? "Saldo de \(name) después" : "\(name) balance after"
    }

    /// "Cheques → FSA"; sin origen, "Otro lugar → FSA".
    func route(from: String?, to: String) -> String {
        (from ?? outsideShort) + " → " + to
    }

    // Bienes
    var asset: String { pick("Item", "Bien") }
    var noAssetsTitle: String { pick("Nothing here yet", "Aún no hay bienes") }
    var noAssetsMessage: String {
        pick("Add things you own, like a house or a car, with what they're worth.",
             "Agrega cosas que tienes, como una casa o un auto, con lo que valen.")
    }
    var addAsset: String { pick("Add item", "Agregar bien") }
    var addAssetHint: String { pick("Add a house, car or anything of value", "Agrega casa, auto o algo de valor") }
    var assetNamePlaceholder: String { pick("e.g. House", "ej. Casa") }
    var assetValue: String { pick("Value", "Valor") }

    func assetCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 bien" : "\(n) bienes" }
        return n == 1 ? "1 item" : "\(n) items"
    }

    func accountCount(_ n: Int) -> String {
        if isSpanish { return n == 1 ? "1 cuenta" : "\(n) cuentas" }
        return n == 1 ? "1 account" : "\(n) accounts"
    }

    var recurringIncome: String { pick("Recurring income", "Ingresos recurrentes") }
    var recurringIncomeItem: String { pick("Recurring income", "Ingreso recurrente") }
    var addRecurringIncome: String { pick("Add recurring income", "Agregar ingreso recurrente") }
    var noRecurringIncome: String { pick("No recurring income", "Sin ingresos recurrentes") }
    var incomeNamePlaceholder: String { pick("e.g. Salary", "ej. Sueldo") }
    var monthlyIncome: String { pick("Monthly income (approx.)", "Ingreso mensual (aprox.)") }
    var amount: String { pick("Amount", "Monto") }
    var amountPerPayment: String { pick("Amount per deposit", "Monto por depósito") }
    var howOften: String { pick("How often", "Cada cuánto") }
    var nextDeposit: String { pick("Next deposit", "Próximo depósito") }
    var dateLabel: String { pick("Date", "Fecha") }
    var recurringIncomeFooter: String {
        pick("Pick a day you got or will get paid (it can be in the past). The next dates are calculated from it, and each deposit is added to your account automatically from the next one on. Extra income is added separately.",
             "Elige un día en que te pagaron o te van a pagar (puede ser pasado). Con eso se calculan las siguientes fechas, y cada depósito se suma solo a tu cuenta desde el próximo. Los ingresos extra se agregan aparte.")
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

    func incomePerMonthShort(_ value: Double) -> String {
        pick("Income ", "Ingreso ") + approxPerMonth(value)
    }

    // Resumen del mes
    var soFar: String { pick("So far", "Hasta hoy") }
    var forecast: String { pick("Forecast", "Pronóstico") }
    var summaryIncome: String { pick("Income", "Ingresos") }
    var summaryPayments: String { pick("Payments", "Pagos") }
    var summaryNet: String { pick("Net", "Neto") }
    var monthSummaryFooter: String {
        pick("Checking accounts only. The forecast adds the rest of the month's recurring income and automatic payments. Transfers between your accounts don't count.",
             "Solo cuentas de cheques. El pronóstico suma lo que falta del mes de ingresos recurrentes y pagos automáticos. Las transferencias entre tus cuentas no cuentan.")
    }

    /// "Resumen de octubre de 2026" / "October 2026 summary".
    func monthSummaryTitle(_ date: Date) -> String {
        isSpanish ? "Resumen de " + monthYearLong(date).lowercased(with: locale) : monthYearLong(date) + " summary"
    }

    var extraIncome: String { pick("Extra income", "Ingreso extra") }
    var addExtraIncome: String { pick("Add extra income", "Agregar ingreso extra") }
    var extraIncomePlaceholder: String { pick("e.g. Bonus", "ej. Bono") }
    var extraIncomeFooter: String {
        pick("One-time income, like a bonus or a sale. It doesn't change your recurring income.",
             "Ingreso de una sola vez, como un bono o una venta. No cambia tu ingreso recurrente.")
    }
    var depositFooter: String {
        pick("Changing this deposit doesn't affect the next ones.",
             "Cambiar este depósito no afecta los siguientes.")
    }

    var historyHint: String {
        pick("Deposits, extra income, payments and transfers are listed in History.",
             "Los depósitos, ingresos extra, pagos y transferencias se ven en Historial.")
    }
    var noMovementsTitle: String { pick("No movements yet", "Aún no hay movimientos") }
    var noMovementsMessage: String {
        pick("Deposits, extra income, payments and transfers will show up here.",
             "Aquí aparecerán los depósitos, ingresos extra, pagos y transferencias.")
    }

    func movementKindName(_ kind: MovementKind) -> String {
        switch kind {
        case .deposit: return pick("Deposit", "Depósito")
        case .extra: return extraIncome
        case .payment: return payment
        case .transfer: return transfer
        }
    }

    /// "+$1,200.00" o "−$500.00".
    func signedMoney(_ value: Double) -> String {
        (value < 0 ? "−" : "+") + money(abs(value))
    }

    // MARK: Pagos

    var pay: String { pick("Pay", "Pagar") }
    var recordPayment: String { pick("Pay a card or loan", "Pagar tarjeta o crédito") }
    var debt: String { pick("Debt", "Deuda") }
    var needsAccount: String { pick("Add an account first.", "Primero agrega una cuenta.") }
    var debtReduction: String { pick("Debt goes down by", "La deuda baja") }
    var debtBalanceAfter: String { pick("Debt after the payment", "Deuda después del pago") }
    var accountBalanceAfter: String { pick("Account balance after", "Saldo de la cuenta después") }

    func includesInstallments(_ value: Double) -> String {
        pick("Includes installment payments", "Incluye mensualidades a meses") + " (" + money(value) + ")"
    }

    var cardPaymentFooter: String {
        pick("It's subtracted from the revolving balance. Installment payments already go down on their own each month, so they aren't subtracted twice.",
             "Se resta del saldo revolvente. Las mensualidades a meses ya bajan solas cada mes, así que no se restan dos veces.")
    }
    // Pago automático
    var autoPay: String { pick("Automatic payment", "Pago automático") }
    var autoPayToggle: String { pick("Pay automatically from an account", "Pagar automáticamente desde una cuenta") }
    var autoPayFooter: String {
        pick("Each month the monthly payment comes out of the account and lowers the debt, like a regular payment.",
             "Cada mes el pago mensual se descuenta de la cuenta y baja la deuda, como un pago normal.")
    }
    var autoPayNeedsAccount: String {
        pick("Add a checking account to pay automatically.", "Agrega una cuenta de cheques para pagar automáticamente.")
    }
    var autoPayNeedsAmount: String { pick("Enter the monthly payment.", "Escribe el pago mensual.") }
    var paymentDay: String { pick("Payment day", "Día de pago") }
    var nextAutoPayment: String { pick("Next automatic payment", "Próximo pago automático") }
    var autoPayments: String { pick("Automatic payments", "Pagos automáticos") }
    var repeatsMonthly: String { pick("Repeats every month", "Se repite cada mes") }
    var firstPayment: String { pick("First payment", "Primer pago") }
    var nextPayment: String { pick("Next payment", "Próximo pago") }
    var recurringPaymentFooter: String {
        pick("It's paid automatically every month starting on that date. It becomes the debt's monthly payment and replaces its automatic payment if it had one.",
             "Se paga solo cada mes desde esa fecha. Queda como el pago mensual de la deuda y reemplaza su pago automático si ya tenía uno.")
    }

    /// "$500.00/mes desde Cheques · próximo 5 nov 2026".
    func autoPaySummary(amount: Double, account: String, next: Date) -> String {
        perMonth(amount) + pick(" from ", " desde ") + account + " · " + pick("next ", "próximo ") + date(next)
    }

    var loanPaymentFooter: String {
        pick("Only the part that goes to principal lowers the balance (payment − this month's interest, approx.).",
             "Solo la parte que va a capital baja el saldo (pago − interés del mes, aprox.).")
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
        guard !hidesAmounts else { return hiddenAmount }
        return value.formatted(.currency(code: currencyCode).locale(locale))
    }

    func moneyWhole(_ value: Double) -> String {
        guard !hidesAmounts else { return hiddenAmount }
        return value.formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(locale))
    }

    private var hiddenAmount: String { "*****" }

    func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(locale)) + "%"
    }

    func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }

    /// "Sábado, 18 de octubre" / "Saturday, October 18".
    func weekdayDate(_ date: Date) -> String {
        let text = date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
        return text.prefix(1).uppercased(with: locale) + text.dropFirst()
    }

    func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    func monthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }

    /// "Octubre de 2026" / "October 2026".
    func monthYearLong(_ date: Date) -> String {
        let text = date.formatted(.dateTime.month(.wide).year().locale(locale))
        return text.prefix(1).uppercased(with: locale) + text.dropFirst()
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
