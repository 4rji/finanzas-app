import SwiftUI

/// Configuración: secciones de inicio (orden y cuáles se muestran), idioma, tamaño de letra y
/// apariencia. Los cambios se ven al momento; Cancelar regresa todo a como estaba al abrir.
struct SettingsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.dismiss) private var dismiss
    /// En una hoja lleva Cancelar / Listo; en la ventana de Configuración de la Mac no hacen falta.
    @Environment(\.isPresented) private var isPresented
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system
    @AppStorage(HomeSection.accounts.storageKey) private var showAccounts = true
    @AppStorage(HomeSection.investments.storageKey) private var showInvestments = true
    @AppStorage(HomeSection.debts.storageKey) private var showDebts = true
    @AppStorage(HomeSection.assets.storageKey) private var showAssets = true
    @AppStorage(HomeSection.orderKey) private var orderRaw = ""

    @State private var snapshot: Snapshot?

    private var order: [HomeSection] { HomeSection.ordered(orderRaw) }

    var body: some View {
        VStack(spacing: 0) {
            ThemedList {
                Section {
                    ForEach(order, id: \.self) { section in
                        row(section)
                    }
                    .onMove { from, to in
                        var sections = order
                        sections.move(fromOffsets: from, toOffset: to)
                        orderRaw = HomeSection.raw(sections)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.homeSettingsTitle)
                            .appFont(.title3, weight: .bold)
                            .foregroundStyle(.primary)
                        Text(t.homeSettingsMessage)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .textCase(nil)
                    .padding(.bottom, 6)
                }

                Section {
                    Picker(t.languageTitle, selection: $language) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    Picker(t.textSizeTitle, selection: $textSize) {
                        ForEach(TextSize.allCases) { size in
                            Text(t.textSizeName(size)).tag(size)
                        }
                    }
                    Picker(t.appearanceTitle, selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(t.appearanceName(option)).tag(option)
                        }
                    }
                } header: {
                    Text(t.generalTitle)
                        .sectionTitle()
                }
            }
            #if os(macOS)
            .listStyle(.inset(alternatesRowBackgrounds: false))
            #else
            // Muestra las agarraderas para arrastrar; los interruptores y menús siguen funcionando.
            .environment(\.editMode, .constant(.active))
            #endif

            if isPresented {
                Divider()
                HStack {
                    Button(t.cancel) {
                        snapshot?.restore(into: self)
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button(t.done) { dismiss() }
                        .keyboardShortcut(.defaultAction)
                        .prominentButton()
                }
                .padding()
            }
        }
        #if os(macOS)
        .frame(width: 480 * scale, height: 560 * scale)
        #endif
        .background(AppBackground())
        .navigationTitle(t.settings)
        .onAppear {
            if snapshot == nil { snapshot = Snapshot(of: self) }
        }
    }

    private func row(_ section: HomeSection) -> some View {
        HStack(spacing: 12) {
            #if os(macOS)
            // En iPhone la agarradera la pone la lista al editar.
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            #endif
            IconTile(systemImage: section.systemImage, tint: section.tint, size: 30)
            Toggle(t.homeSectionName(section), isOn: isShown(section))
                .appFont(.body, weight: .medium)
        }
        .padding(.vertical, 2)
    }

    private func isShown(_ section: HomeSection) -> Binding<Bool> {
        switch section {
        case .accounts: return $showAccounts
        case .investments: return $showInvestments
        case .debts: return $showDebts
        case .assets: return $showAssets
        }
    }

    /// Valores al abrir, para que Cancelar los regrese.
    private struct Snapshot {
        let language: AppLanguage
        let textSize: TextSize
        let appearance: AppAppearance
        let shown: [HomeSection: Bool]
        let orderRaw: String

        init(of view: SettingsView) {
            language = view.language
            textSize = view.textSize
            appearance = view.appearance
            shown = Dictionary(uniqueKeysWithValues: HomeSection.allCases.map { ($0, view.isShown($0).wrappedValue) })
            orderRaw = view.orderRaw
        }

        func restore(into view: SettingsView) {
            view.language = language
            view.textSize = textSize
            view.appearance = appearance
            for (section, isOn) in shown {
                view.isShown(section).wrappedValue = isOn
            }
            view.orderRaw = orderRaw
        }
    }
}
