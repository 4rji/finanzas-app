import SwiftUI

/// Los cambios se ven al momento; Cancelar restaura los valores con los que se abrió la pantalla.
struct SettingsView: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .deviceDefault
    @AppStorage(TextSize.storageKey) private var textSize: TextSize = .large
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system
    @AppStorage(BackgroundStyle.storageKey) private var background: BackgroundStyle = .mint
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeading(t.homeSettingsTitle, subtitle: t.homeSettingsMessage)
                    ForEach(order, id: \.self) { section in
                        homeRow(section)
                            .draggable(section.rawValue)
                            .dropDestination(for: String.self) { items, _ in
                                guard items.count == 1,
                                      let raw = items.first,
                                      let source = HomeSection(rawValue: raw) else { return false }
                                return moveSection(source, onto: section)
                            }
                            .accessibilityAction(named: Text(t.previousSection)) {
                                moveSection(section, by: -1)
                            }
                            .accessibilityAction(named: Text(t.nextSection)) {
                                moveSection(section, by: 1)
                            }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionHeading(t.generalTitle)
                    SettingsCard(systemImage: "circle.lefthalf.filled", tint: .sand, title: t.appearanceTitle) {
                        HStack(spacing: 10) {
                            ForEach([AppAppearance.light, .dark, .system]) { option in
                                SettingsChoice(isSelected: appearance == option, tint: .mint) {
                                    appearance = option
                                } label: {
                                    Image(systemName: appearanceIcon(option))
                                        .font(.system(size: 25 * scale, weight: .semibold))
                                        .frame(height: 34 * scale)
                                        .frame(maxWidth: .infinity)
                                }
                                .accessibilityLabel(t.appearanceName(option))
                                .help(t.appearanceName(option))
                            }
                        }
                    }

                    SettingsCard(systemImage: "paintpalette", tint: .peach, title: t.backgroundTitle, subtitle: t.backgroundHint) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76 * scale), spacing: 10)], spacing: 10) {
                            ForEach(BackgroundStyle.allCases) { option in
                                SettingsChoice(isSelected: background == option, tint: .mint) {
                                    background = option
                                } label: {
                                    VStack(spacing: 7) {
                                        BackgroundSwatch(style: option)
                                            .frame(height: 30 * scale)
                                        Text(t.backgroundName(option))
                                            .appFont(.subheadline, weight: .semibold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .accessibilityLabel(t.backgroundName(option))
                            }
                        }
                    }

                    SettingsCard(systemImage: "globe", tint: .teal, title: t.languageTitle, subtitle: t.languageHint) {
                        HStack(spacing: 10) {
                            ForEach(AppLanguage.allCases) { option in
                                SettingsChoice(isSelected: language == option, tint: .teal) {
                                    language = option
                                } label: {
                                    VStack(spacing: 5) {
                                        Text(option.rawValue.uppercased())
                                            .font(.system(size: 11 * scale, weight: .bold, design: .rounded))
                                            .tracking(1.5)
                                            .opacity(0.75)
                                        Text(option.displayName)
                                            .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .accessibilityLabel(option.displayName)
                            }
                        }
                    }

                    SettingsCard(systemImage: "textformat.size", tint: .sage, title: t.textSizeTitle, subtitle: t.textSizeHint) {
                        HStack(spacing: 8) {
                            ForEach(TextSize.allCases) { size in
                                SettingsChoice(isSelected: textSize == size, tint: .mint) {
                                    textSize = size
                                } label: {
                                    VStack(spacing: 7) {
                                        Text("A")
                                            .font(.system(size: sizeSample(size) * scale, weight: .semibold, design: .rounded))
                                            .frame(height: 28 * scale)
                                        Text(t.textSizeName(size))
                                            .appFont(.subheadline, weight: .semibold)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(minHeight: 28 * scale)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .accessibilityLabel(t.textSizeName(size))
                            }
                        }
                    }

                    SettingsToggleRow(
                        systemImage: "eye.slash", tint: .peach, title: t.hideAmounts,
                        subtitle: t.hideAmountsHint, isOn: $hidesAmounts
                    )
                }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isPresented {
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .frame(minWidth: 340, idealWidth: 620, minHeight: 520, idealHeight: 760)
        #endif
        .background(AppBackground())
        .navigationTitle(t.settings)
        .onAppear {
            if snapshot == nil { snapshot = Snapshot(of: self) }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            IconTile(systemImage: "gearshape.2.fill", tint: .mint, size: 46, filled: true)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(t.appName)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.secondary)
                Text(t.settings)
                    .font(.system(size: 28 * scale, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            if isPresented {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36 * scale, height: 36 * scale)
                        .background(Color.primary.opacity(0.055), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.close)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 18)
    }

    private func sectionHeading(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 19 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .textCase(nil)
        .padding(.horizontal, 6)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(t.cancel) {
                snapshot?.restore(into: self)
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .font(.system(size: 15 * scale, weight: .semibold, design: .rounded))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Button(t.done) { dismiss() }
                .keyboardShortcut(.defaultAction)
                .font(.system(size: 15 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: ThemeTint.mint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1) }
    }

    private func homeRow(_ section: HomeSection) -> some View {
        HStack(spacing: 10) {
            #if os(macOS)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12 * scale, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            #endif
            SettingsToggleRow(
                systemImage: section.systemImage, tint: section.tint,
                title: t.homeSectionName(section),
                subtitle: isShown(section).wrappedValue ? t.shownOnHome : t.hiddenFromHome,
                isOn: isShown(section), drawsSurface: false
            )
        }
        .padding(16)
        .settingsSurface()
    }

    private func appearanceIcon(_ option: AppAppearance) -> String {
        switch option {
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        case .system: return "desktopcomputer"
        }
    }

    private func sizeSample(_ size: TextSize) -> CGFloat {
        switch size {
        case .normal: return 17
        case .large: return 22
        case .extraLarge: return 27
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

    @discardableResult
    private func moveSection(_ source: HomeSection, onto destination: HomeSection) -> Bool {
        var sections = order
        guard source != destination,
              let from = sections.firstIndex(of: source),
              let to = sections.firstIndex(of: destination) else { return false }
        sections.move(fromOffsets: IndexSet(integer: from), toOffset: from < to ? to + 1 : to)
        orderRaw = HomeSection.raw(sections)
        return true
    }

    private func moveSection(_ section: HomeSection, by offset: Int) {
        guard let index = order.firstIndex(of: section),
              order.indices.contains(index + offset) else { return }
        moveSection(section, onto: order[index + offset])
    }

    /// Valores al abrir, para que Cancelar los regrese.
    private struct Snapshot {
        let language: AppLanguage
        let textSize: TextSize
        let appearance: AppAppearance
        let background: BackgroundStyle
        let hidesAmounts: Bool
        let shown: [HomeSection: Bool]
        let orderRaw: String

        init(of view: SettingsView) {
            language = view.language
            textSize = view.textSize
            appearance = view.appearance
            background = view.background
            hidesAmounts = view.hidesAmounts
            shown = Dictionary(uniqueKeysWithValues: HomeSection.allCases.map { ($0, view.isShown($0).wrappedValue) })
            orderRaw = view.orderRaw
        }

        func restore(into view: SettingsView) {
            view.language = language
            view.textSize = textSize
            view.appearance = appearance
            view.background = background
            view.hidesAmounts = hidesAmounts
            for (section, isOn) in shown {
                view.isShown(section).wrappedValue = isOn
            }
            view.orderRaw = orderRaw
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @Environment(\.textScale) private var scale
    let systemImage: String
    let tint: ThemeTint
    let title: String
    let subtitle: String?
    let content: Content

    init(systemImage: String, tint: ThemeTint, title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.systemImage = systemImage
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                IconTile(systemImage: systemImage, tint: tint, size: 36, filled: true)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16 * scale, weight: .semibold, design: .rounded))
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .appFont(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .settingsSurface()
    }
}

private struct SettingsToggleRow: View {
    @Environment(\.textScale) private var scale
    let systemImage: String
    let tint: ThemeTint
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var drawsSurface = true

    var body: some View {
        HStack(spacing: 10) {
            IconTile(systemImage: systemImage, tint: tint, size: 32, filled: true)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15 * scale, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .appFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SettingsCheckboxStyle(tint: tint))
        }
        .padding(drawsSurface ? 18 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if drawsSurface { SettingsSurface() }
        }
    }
}

/// Una casilla con proporciones propias que expone el control Toggle nativo a accesibilidad.
private struct SettingsCheckboxStyle: ToggleStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let tint: ThemeTint

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9 * scale, style: .continuous)
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack {
                if configuration.isOn {
                    shape.fill(LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "checkmark")
                        .font(.system(size: 14 * scale, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    shape.fill(Color.primary.opacity(0.035))
                }
            }
            .frame(width: 30 * scale, height: 30 * scale)
            .overlay(shape.strokeBorder(configuration.isOn ? .white.opacity(0.15) : Color.primary.opacity(0.16), lineWidth: 1))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}

private struct SettingsChoice<Label: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let isSelected: Bool
    let tint: ThemeTint
    let action: () -> Void
    let label: Label

    init(isSelected: Bool, tint: ThemeTint, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isSelected = isSelected
        self.tint = tint
        self.action = action
        self.label = label()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button(action: action) {
            label
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 14 * scale)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        shape.fill(LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing))
                    } else {
                        shape.fill(Color.primary.opacity(scheme == .dark ? 0.04 : 0.035))
                    }
                }
                .overlay(shape.strokeBorder(isSelected ? .white.opacity(0.18) : Color.primary.opacity(0.06), lineWidth: 1))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Muestra chica de un fondo, con su color más intenso para que se distinga.
private struct BackgroundSwatch: View {
    @Environment(\.colorScheme) private var scheme
    let style: BackgroundStyle

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        ZStack {
            LinearGradient(colors: style.colors(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [style.glow(scheme), style.glow(scheme).opacity(0.25)], startPoint: .topTrailing, endPoint: .bottomLeading)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

private struct SettingsSurface: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        shape
            .fill(scheme == .dark ? Color(hex: 0x1A261F) : .white)
            .overlay(shape.strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

private extension View {
    func settingsSurface() -> some View {
        background(SettingsSurface())
    }

}
