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

    /// Lo que cada pago bajó la deuda total, sin las deudas que no se suman al total. Los cargos no
    /// quedan como movimientos, así que la línea solo baja con los pagos.
    static func debtChanges(_ movements: [Movement], asOf now: Date = Date()) -> [Double] {
        movements
            .filter { $0.kind == .payment && $0.date <= now && $0.debt?.excludedFromTotal == false }
            .sorted { $0.date < $1.date }
            .map { -$0.appliedToDebt }
            .filter { $0 != 0 }
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
