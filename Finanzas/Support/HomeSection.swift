import Foundation

/// Categorías de la pantalla de inicio. En Configuración se pueden reordenar y ocultar las que no se usan.
enum HomeSection: String, CaseIterable {
    case accounts
    case investments
    case debts
    case assets

    static let orderKey = "homeOrder"
    /// Última tarjeta elegida en el carrusel de inicio.
    static let selectedKey = "homeSelected"

    var storageKey: String { "showOnHome." + rawValue }

    var systemImage: String {
        switch self {
        case .accounts: return AccountKind.checking.systemImage
        case .investments: return AccountKind.investment.systemImage
        case .debts: return "creditcard"
        case .assets: return "tag"
        }
    }

    /// Orden guardado ("debts,accounts,…"). Lo que falte se agrega al final en el orden normal.
    static func ordered(_ raw: String) -> [HomeSection] {
        var sections = raw.split(separator: ",").compactMap { HomeSection(rawValue: String($0)) }
        for section in allCases where !sections.contains(section) {
            sections.append(section)
        }
        return sections
    }

    static func raw(_ sections: [HomeSection]) -> String {
        sections.map(\.rawValue).joined(separator: ",")
    }
}

/// Cómo se ven las tarjetas de inicio: carrusel que se desliza de lado o cuadrícula con todas a la vista.
enum HomeLayout: String {
    case carousel
    case grid

    static let storageKey = "homeLayout"
}
