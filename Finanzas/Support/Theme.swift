import SwiftUI

/// Colores de cada categoría: verdes y tonos suaves, cada uno con versión clara y oscura.
enum ThemeTint {
    case mint
    case teal
    case sage
    case peach
    case sand

    /// Color sólido para íconos, montos y barras.
    func solid(_ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch self {
        case .mint: return Color(hex: dark ? 0x6BD9A8 : 0x2A9A6C)
        case .teal: return Color(hex: dark ? 0x6CD3CF : 0x20878D)
        case .sage: return Color(hex: dark ? 0xB5D58A : 0x6B8F43)
        case .peach: return Color(hex: dark ? 0xF0A584 : 0xC96E4E)
        case .sand: return Color(hex: dark ? 0xE2C27F : 0x9C7A33)
        }
    }

    /// Degradado de las tarjetas de color.
    func gradient(_ scheme: ColorScheme) -> [Color] {
        let dark = scheme == .dark
        switch self {
        case .mint: return dark ? [Color(hex: 0x1D6F55), Color(hex: 0x3BAA80)] : [Color(hex: 0x34B37F), Color(hex: 0x7ED6AE)]
        case .teal: return dark ? [Color(hex: 0x17626A), Color(hex: 0x2F9C9A)] : [Color(hex: 0x2A9FA6), Color(hex: 0x7FD3D1)]
        case .sage: return dark ? [Color(hex: 0x4A6634), Color(hex: 0x7D9F55)] : [Color(hex: 0x86AC5E), Color(hex: 0xC3DB97)]
        case .peach: return dark ? [Color(hex: 0x87493A), Color(hex: 0xC07A5E)] : [Color(hex: 0xE8906F), Color(hex: 0xF4C09F)]
        case .sand: return dark ? [Color(hex: 0x6E5A2E), Color(hex: 0xA88B4E)] : [Color(hex: 0xC9A45C), Color(hex: 0xE8D29A)]
        }
    }
}

extension AccountKind {
    var tint: ThemeTint {
        switch self {
        case .checking: return .mint
        case .investment: return .teal
        case .goal: return .sage
        }
    }
}

extension DebtKind {
    var tint: ThemeTint {
        switch self {
        case .creditCard: return .peach
        case .mortgage: return .sand
        case .autoLoan: return .teal
        case .studentLoan: return .sage
        }
    }
}

extension MovementKind {
    var tint: ThemeTint {
        switch self {
        case .deposit, .extra: return .mint
        case .payment: return .peach
        case .transfer: return .teal
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Fondo

/// Fondo de todas las pantallas: un tono base con manchas de luz verde y aqua.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark

        ZStack {
            Color(hex: dark ? 0x07120E : 0xEFF6F1)
            RadialGradient(
                colors: [Color(hex: dark ? 0x1B5240 : 0xBFE8D3, opacity: dark ? 0.85 : 0.9), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 560
            )
            RadialGradient(
                colors: [Color(hex: dark ? 0x123E40 : 0xCDEBEA, opacity: 0.9), .clear],
                center: .bottomLeading, startRadius: 0, endRadius: 600
            )
            RadialGradient(
                colors: [Color(hex: dark ? 0x2C4A22 : 0xE6F0D2, opacity: 0.6), .clear],
                center: UnitPoint(x: 0.15, y: 0.2), startRadius: 0, endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
}

/// Fondo translúcido de las filas de los formularios y listas.
struct RowBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        scheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.72)
    }
}

/// Form agrupado sobre el fondo de la app, con filas translúcidas.
struct ThemedForm<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Form {
            Group { content }
                .listRowBackground(RowBackground())
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

/// Lista sobre el fondo de la app, con filas translúcidas.
struct ThemedList<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        List {
            Group { content }
                .listRowBackground(RowBackground())
        }
        .scrollContentBackground(.hidden)
    }
}

extension View {
    /// Pone el fondo de la app detrás de toda la pantalla.
    func screenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackground())
    }

    /// Título de sección: mayúsculas chicas con espacio entre letras.
    func sectionTitle() -> some View {
        appFont(.subheadline, weight: .bold)
            .textCase(.uppercase)
            .tracking(1.1)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Vidrio líquido

extension View {
    /// Vidrio líquido en iOS 26 / macOS 26; antes, material translúcido con un borde fino.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(interactive ? .regular.tint(tint).interactive() : .regular.tint(tint), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }

    /// Botón principal de vidrio con el color de la app.
    @ViewBuilder
    func prominentButton() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}

/// Las tarjetas se encogen un poco al tocarlas, con rebote.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Adornos

/// Ícono dentro de un cuadrito redondeado con el color de su categoría.
struct IconTile: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let systemImage: String
    let tint: ThemeTint
    var size: CGFloat = 34

    var body: some View {
        let side = size * scale

        Image(systemName: systemImage)
            .font(.system(size: side * 0.46, weight: .semibold, design: .rounded))
            .foregroundStyle(tint.solid(scheme))
            .frame(width: side, height: side)
            .background(
                tint.solid(scheme).opacity(scheme == .dark ? 0.18 : 0.14),
                in: RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
            )
    }
}

/// Tarjetita de color con su ícono, como una mini tarjeta de banco.
struct CardChip: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let systemImage: String
    let tint: ThemeTint

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9 * scale, style: .continuous)

        Image(systemName: systemImage)
            .font(.system(size: 15 * scale, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 46 * scale, height: 32 * scale)
            .background {
                ZStack {
                    LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                    Bubbles()
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
    }
}

/// Círculos translúcidos de adorno para las tarjetas de color.
struct Bubbles: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: h * 1.1, height: h * 1.1)
                    .position(x: w * 0.9, y: h * 0.1)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: h * 0.95, height: h * 0.95)
                    .position(x: w * 0.1, y: h * 1.02)
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: h * 0.26, height: h * 0.26)
                    .position(x: w * 0.64, y: h * 0.8)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Ola de adorno al pie de las tarjetas. No representa datos; `seed` solo cambia su forma.
struct WaveDecoration: View {
    @Environment(\.colorScheme) private var scheme
    let tint: ThemeTint
    var seed: Int = 0

    var body: some View {
        let color = tint.solid(scheme)

        ZStack {
            WaveShape(seed: seed, closed: true)
                .fill(LinearGradient(colors: [color.opacity(0.22), color.opacity(0)], startPoint: .top, endPoint: .bottom))
            WaveShape(seed: seed, closed: false)
                .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

private struct WaveShape: Shape {
    let seed: Int
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Tres formas que se alternan para que las tarjetas no se vean iguales.
        let heights: [(CGFloat, CGFloat, CGFloat)] = [(0.7, 0.45, 0.2), (0.4, 0.65, 0.25), (0.6, 0.3, 0.45)]
        let (start, middle, end) = heights[abs(seed) % heights.count]

        var path = Path()
        path.move(to: CGPoint(x: 0, y: h * start))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * middle),
            control1: CGPoint(x: w * 0.2, y: h * (start - 0.35)),
            control2: CGPoint(x: w * 0.3, y: h * (middle + 0.35))
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * end),
            control1: CGPoint(x: w * 0.7, y: h * (middle - 0.35)),
            control2: CGPoint(x: w * 0.85, y: h * (end + 0.2))
        )
        if closed {
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.closeSubpath()
        }
        return path
    }
}
