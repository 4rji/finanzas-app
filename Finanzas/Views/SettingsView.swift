import SwiftUI

/// Configuración: secciones de inicio (orden y cuáles se muestran), idioma, tamaño de letra,
/// apariencia y saldos ocultos. Los cambios se ven al momento; Cancelar regresa todo a como estaba.
struct SettingsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.dismiss) private var dismiss
    /// En una hoja lleva cerrar, Cancelar y Listo; en la ventana de Configuración de la Mac no hacen falta.
    @Environment(\.isPresented) private var isPresented
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system
    @AppStorage(L10n.hidesAmountsKey) private var hidesAmounts = false
    @AppStorage(HomeSection.accounts.storageKey) private var showAccounts = true
    @AppStorage(HomeSection.investments.storageKey) private var showInvestments = true
    @AppStorage(HomeSection.debts.storageKey) private var showDebts = true
    @AppStorage(HomeSection.assets.storageKey) private var showAssets = true
    @AppStorage(HomeSection.orderKey) private var orderRaw = ""

    @State private var snapshot: Snapshot?

    private var order: [HomeSection] { HomeSection.ordered(orderRaw) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ThemedList {
                Section {
                    ForEach(order, id: \.self) { section in
                        homeRow(section)
                    }
                    .onMove { from, to in
                        var sections = order
                        sections.move(fromOffsets: from, toOffset: to)
                        orderRaw = HomeSection.raw(sections)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.homeSettingsTitle)
                            .sectionTitle()
                        Text(t.homeSettingsMessage)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                    .padding(.bottom, 4)
                }

                Section {
                    SettingsRow(systemImage: "globe", tint: .teal, title: t.languageTitle, subtitle: t.languageHint) {
                        Picker(t.languageTitle, selection: $language) {
                            ForEach(AppLanguage.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                    SettingsRow(systemImage: "textformat.size", tint: .sage, title: t.textSizeTitle, subtitle: t.textSizeHint) {
                        Picker(t.textSizeTitle, selection: $textSize) {
                            ForEach(TextSize.allCases) { size in
                                Text(t.textSizeName(size)).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                    SettingsRow(
                        systemImage: "circle.lefthalf.filled", tint: .sand,
                        title: t.appearanceTitle, subtitle: t.appearanceHint
                    ) {
                        Picker(t.appearanceTitle, selection: $appearance) {
                            ForEach(AppAppearance.allCases) { option in
                                Text(t.appearanceName(option)).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .fixedSize()
                    }
                    SettingsRow(systemImage: "eye.slash", tint: .peach, title: t.hideAmounts, subtitle: t.hideAmountsHint) {
                        Toggle(t.hideAmounts, isOn: $hidesAmounts)
                            .labelsHidden()
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
                    .glassButton()
                    Spacer()
                    Button(t.done) { dismiss() }
                        .keyboardShortcut(.defaultAction)
                        .prominentButton()
                }
                .padding()
            }
        }
        #if os(macOS)
        .frame(width: 500 * scale, height: 640 * scale)
        #endif
        .background(AppBackground())
        .navigationTitle(t.settings)
        .onAppear {
            if snapshot == nil { snapshot = Snapshot(of: self) }
        }
    }

    /// Título centrado en mayúsculas con el botón de cerrar a la derecha.
    private var header: some View {
        ZStack {
            Text(t.settings)
                .appFont(.title3, weight: .heavy)
                .textCase(.uppercase)
                .tracking(2.4)
                .foregroundStyle(.secondary)
            if isPresented {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Label(t.close, systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                    .glassButton()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private func homeRow(_ section: HomeSection) -> some View {
        HStack(spacing: 10) {
            #if os(macOS)
            // En iPhone la agarradera la pone la lista al editar.
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            #endif
            SettingsRow(
                systemImage: section.systemImage,
                tint: section.tint,
                title: t.homeSectionName(section),
                subtitle: isShown(section).wrappedValue ? t.shownOnHome : t.hiddenFromHome
            ) {
                Toggle(t.homeSectionName(section), isOn: isShown(section))
                    .labelsHidden()
            }
        }
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
        let hidesAmounts: Bool
        let shown: [HomeSection: Bool]
        let orderRaw: String

        init(of view: SettingsView) {
            language = view.language
            textSize = view.textSize
            appearance = view.appearance
            hidesAmounts = view.hidesAmounts
            shown = Dictionary(uniqueKeysWithValues: HomeSection.allCases.map { ($0, view.isShown($0).wrappedValue) })
            orderRaw = view.orderRaw
        }

        func restore(into view: SettingsView) {
            view.language = language
            view.textSize = textSize
            view.appearance = appearance
            view.hidesAmounts = hidesAmounts
            for (section, isOn) in shown {
                view.isShown(section).wrappedValue = isOn
            }
            view.orderRaw = orderRaw
        }
    }
}

/// Fila de menú: ícono de color, título con una descripción corta y el control a la derecha.
private struct SettingsRow<Control: View>: View {
    let systemImage: String
    let tint: ThemeTint
    let title: String
    let subtitle: String
    let control: Control

    init(systemImage: String, tint: ThemeTint, title: String, subtitle: String, @ViewBuilder control: () -> Control) {
        self.systemImage = systemImage
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemImage: systemImage, tint: tint, size: 36, filled: true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appFont(.body, weight: .semibold)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            control
        }
        .padding(.vertical, 4)
    }
}
