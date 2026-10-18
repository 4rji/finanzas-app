import Foundation
import SwiftData

/// Algo de valor que tienes, como una casa o un auto. Solo nombre y valor; no se suma a ninguna cuenta.
@Model
final class Asset {
    var name: String = ""
    var createdAt: Date = Date()
    var value: Double = 0

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
