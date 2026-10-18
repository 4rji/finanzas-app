import Foundation

/// Categorías de la pantalla de inicio. En Configuración se pueden ocultar las que no se usan.
enum HomeSection: String, CaseIterable {
    case accounts
    case investments
    case debts
    case assets

    var storageKey: String { "showOnHome." + rawValue }
}
