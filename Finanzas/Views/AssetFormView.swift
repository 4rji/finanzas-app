import SwiftUI
import SwiftData

/// Alta o edición de un bien: solo nombre y valor.
struct AssetFormView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context

    let asset: Asset?

    @State private var name: String
    @State private var valueText: String

    init(asset: Asset? = nil) {
        self.asset = asset
        _name = State(initialValue: asset?.name ?? "")
        _valueText = State(initialValue: editText(asset?.value ?? 0))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        FormSheet(canSave: !trimmedName.isEmpty, onSave: save, onDelete: asset == nil ? nil : delete) {
            Section {
                TextRow(title: t.name, text: $name, prompt: t.assetNamePlaceholder)
                DecimalField(title: t.assetValue, text: $valueText, prefix: t.currencySymbol)
            } header: {
                Label(t.asset, systemImage: "tag")
                    .sectionTitle()
            }
        }
    }

    private func save() {
        let target: Asset
        if let asset {
            target = asset
        } else {
            target = Asset(name: trimmedName)
            context.insert(target)
        }
        let value = parseDecimal(valueText)
        let change = value - target.value
        target.name = trimmedName
        target.value = value
        if change != 0 {
            let record = AssetChange(amount: change)
            context.insert(record)
            record.asset = target
        }
        try? context.save()
    }

    private func delete() {
        guard let asset else { return }
        context.delete(asset)
        try? context.save()
    }
}
