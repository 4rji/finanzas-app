import Foundation

/// Cómo fue cambiando el saldo total de las cuentas de cheques, para dibujar su línea.
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

    /// Lo que cada movimiento cambió el total de las cuentas de cheques, del más viejo al más nuevo
    /// y sin los que tienen fecha futura. Las transferencias entre dos cuentas de cheques se anulan.
    static func checkingChanges(_ movements: [Movement], asOf now: Date = Date()) -> [Double] {
        movements
            .filter { $0.date <= now }
            .sorted { $0.date < $1.date }
            .map { movement in
                var change = movement.account?.kind == .checking ? movement.signedAmount : 0
                if movement.kind == .transfer, movement.toAccount?.kind == .checking {
                    change += movement.amount
                }
                return change
            }
            .filter { $0 != 0 }
    }
}
