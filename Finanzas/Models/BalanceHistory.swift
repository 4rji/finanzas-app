import Foundation

/// Cómo fue cambiando el total de cada sección del inicio, para dibujar su línea.
enum BalanceHistory {
    /// Saldos de más viejo a más nuevo, terminando en `current`. `changes` es lo que movió cada
    /// movimiento, en orden de fecha. Sin cambios queda una línea recta.
    static func points(current: Double, changes: [Double], limit: Int = 30) -> [Double] {
        let recent = changes.suffix(limit)
        var balance = current - recent.reduce(0, +)
        var points = [balance]
        for change in recent {
            balance += change
            points.append(balance)
        }
        return points.count > 1 ? points : [current, current]
    }

    /// Lo que cada movimiento cambió el total de las cuentas que cumplen `includes`, del más viejo al
    /// más nuevo y sin los que tienen fecha futura. Las transferencias entre dos de esas cuentas se
    /// anulan.
    static func accountChanges(
        _ movements: [Movement],
        asOf now: Date = Date(),
        includes: (AccountKind) -> Bool
    ) -> [Double] {
        movements
            .filter { $0.date <= now }
            .sorted { $0.date < $1.date }
            .map { movement in
                var change = movement.account.map { includes($0.kind) } == true ? movement.signedAmount : 0
                if movement.kind == .transfer, let to = movement.toAccount, includes(to.kind) {
                    change += movement.amount
                }
                return change
            }
            .filter { $0 != 0 }
    }

    /// Un cambio de lo que se debe: los pagos la bajan y las ediciones o compras a meses la suben o
    /// la bajan.
    struct DebtEvent {
        let date: Date
        let change: Double
    }

    /// Cambios de lo que se debe en `debts`, del más viejo al más nuevo y sin fechas futuras. Las
    /// mensualidades a meses bajan solas cada mes y no quedan anotadas, así que es aproximado.
    static func debtEvents(for debts: [Debt], asOf now: Date = Date()) -> [DebtEvent] {
        debts
            .flatMap { debt -> [DebtEvent] in
                let payments = (debt.payments ?? [])
                    .filter { $0.kind == .payment }
                    .map { DebtEvent(date: $0.date, change: -$0.appliedToDebt) }
                let edits = (debt.changes ?? []).map { DebtEvent(date: $0.date, change: $0.amount) }
                return payments + edits
            }
            .filter { $0.date <= now && $0.change != 0 }
            .sorted { $0.date < $1.date }
    }

    /// Un punto de la gráfica: lo que se debía después de los cambios de esa fecha.
    struct Point: Identifiable {
        let id: Int
        let date: Date
        let value: Double
    }

    /// Puntos de `start` a `now` que terminan en `current`. El primero es lo que se debía al empezar.
    static func series(current: Double, events: [DebtEvent], from start: Date, to now: Date = Date()) -> [Point] {
        let inRange = events.filter { $0.date > start && $0.date <= now }
        var value = current - inRange.reduce(0) { $0 + $1.change }
        var points = [Point(id: 0, date: start, value: value)]
        for event in inRange {
            value += event.change
            points.append(Point(id: points.count, date: event.date, value: value))
        }
        points.append(Point(id: points.count, date: now, value: current))
        return points
    }

    /// Lo que cambió el valor total de los bienes cada vez que se editó uno.
    static func assetChanges(_ changes: [AssetChange], asOf now: Date = Date()) -> [Double] {
        changes
            .filter { $0.asset != nil && $0.date <= now }
            .sorted { $0.date < $1.date }
            .map(\.amount)
            .filter { $0 != 0 }
    }
}
