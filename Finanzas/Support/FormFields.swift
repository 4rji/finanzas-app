import SwiftUI

/// Hoja con formulario y botones Cancelar / Guardar abajo, al estilo macOS.
/// Esc cancela y Enter guarda.
struct FormSheet<Content: View>: View {
    @Environment(\.l10n) private var t
    @Environment(\.dismiss) private var dismiss

    let canSave: Bool
    let onSave: () -> Void
    let onDelete: (() -> Void)?
    let content: Content

    init(
        canSave: Bool = true,
        onSave: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.canSave = canSave
        self.onSave = onSave
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                content
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if let onDelete {
                    Button(t.delete, role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
                Spacer()
                Button(t.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(t.save) {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding()
        }
        .frame(minWidth: 460, minHeight: 420)
    }
}

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
                if let suffix {
                    Text(suffix).foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension Color {
    static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
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
