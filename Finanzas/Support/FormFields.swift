import SwiftUI

/// Fila de formulario con título a la izquierda y campo de texto a la derecha.
struct TextRow: View {
    let title: String
    @Binding var text: String
    var prompt: String = ""

    var body: some View {
        LabeledContent(title) {
            TextField(title, text: $text, prompt: Text(prompt))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
        }
    }
}

/// Campo numérico. Guarda el texto tal cual y se convierte con `parseDecimal` al guardar.
struct DecimalField: View {
    let title: String
    @Binding var text: String
    var prefix: String?
    var suffix: String?

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 4) {
                if let prefix {
                    Text(prefix).foregroundStyle(.secondary)
                }
                TextField(title, text: $text, prompt: Text("0"))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .decimalKeyboard()
                if let suffix {
                    Text(suffix).foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Tamaño mínimo para las hojas (sheets) en macOS.
    @ViewBuilder
    func macSheetSize() -> some View {
        #if os(macOS)
        self.frame(minWidth: 460, minHeight: 420)
        #else
        self
        #endif
    }
}

extension Color {
    static var groupedBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemGroupedBackground)
        #endif
    }

    static var cardBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}

/// Convierte texto como "1,234.50", "1.234,50", "$ 2500" o "18,5" a número.
func parseDecimal(_ text: String) -> Double {
    var s = text.filter { "0123456789.,-".contains($0) }
    let lastDot = s.lastIndex(of: ".")
    let lastComma = s.lastIndex(of: ",")

    if let dot = lastDot, let comma = lastComma {
        if dot > comma {
            s.removeAll(where: { $0 == "," })
        } else {
            s.removeAll(where: { $0 == "." })
            s = s.replacingOccurrences(of: ",", with: ".")
        }
    } else if lastComma != nil {
        let parts = s.split(separator: ",", omittingEmptySubsequences: false)
        if parts.count == 2 && parts[1].count <= 2 {
            s = s.replacingOccurrences(of: ",", with: ".")
        } else {
            s.removeAll(where: { $0 == "," })
        }
    } else if s.filter({ $0 == "." }).count > 1 {
        s.removeAll(where: { $0 == "." })
    }
    return Double(s) ?? 0
}

/// Texto inicial para editar un número existente ("" si es 0).
func editText(_ value: Double) -> String {
    guard value != 0 else { return "" }
    return value.formatted(
        .number.grouping(.never).precision(.fractionLength(0...2)).locale(Locale(identifier: "en_US_POSIX"))
    )
}
