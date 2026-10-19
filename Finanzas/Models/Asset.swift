import Foundation
import SwiftData

/// Algo de valor que tienes, como una casa o un auto. Solo nombre y valor; no se suma a ninguna cuenta.
@Model
final class Asset {
    var name: String = ""
    var createdAt: Date = Date()
    var value: Double = 0

    /// Cada cambio de valor, para la línea de los bienes en el inicio.
    @Relationship(deleteRule: .cascade, inverse: \AssetChange.asset)
    var changes: [AssetChange]? = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

/// Cuánto subió o bajó el valor de un bien y cuándo.
@Model
final class AssetChange {
    var date: Date = Date()
    var amount: Double = 0
    var asset: Asset?

    init(amount: Double, date: Date = Date()) {
        self.amount = amount
        self.date = date
    }
}
