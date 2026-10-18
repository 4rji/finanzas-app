import SwiftUI
import SwiftData

/// Bienes como una casa o un auto: solo nombre y valor.
struct AssetsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.modelContext) private var context
    @Query(sort: \Asset.createdAt) private var assets: [Asset]

    @State private var adding = false
    @State private var editing: Asset?

    var body: some View {
        Group {
            if assets.isEmpty {
                ContentUnavailableView {
                    Label(t.noAssetsTitle, systemImage: "tag")
                } description: {
                    Text(t.noAssetsMessage)
                } actions: {
                    Button(t.addAsset) { adding = true }
                }
            } else {
                Form {
                    Section {
                        ForEach(assets) { asset in
                            Button {
                                editing = asset
                            } label: {
                                AssetRow(asset: asset)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(t.edit) { editing = asset }
                                Button(t.delete, role: .destructive) { delete(asset) }
                            }
                        }
                        if assets.count > 1 {
                            LabeledContent(t.totalValue) {
                                Text(t.money(assets.reduce(0) { $0 + $1.value }))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .navigationTitle(t.assets)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    adding = true
                } label: {
                    Label(t.add, systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $adding) {
            AssetFormView()
        }
        .sheet(item: $editing) { asset in
            AssetFormView(asset: asset)
        }
    }

    private func delete(_ asset: Asset) {
        context.delete(asset)
        try? context.save()
    }
}

private struct AssetRow: View {
    @Environment(\.l10n) private var t
    let asset: Asset

    var body: some View {
        HStack(spacing: 12) {
            Label(asset.name, systemImage: "tag")
                .appFont(.body, weight: .medium)
            Spacer()
            Text(t.money(asset.value))
                .appFont(.title3, weight: .semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
