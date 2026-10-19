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

    /// Degradado de las tarjetas de color, con profundidad suficiente para texto blanco.
    func gradient(_ scheme: ColorScheme) -> [Color] {
        let dark = scheme == .dark
        switch self {
        case .mint: return dark ? [Color(hex: 0x164D3D), Color(hex: 0x23634B)] : [Color(hex: 0x165440), Color(hex: 0x22694D)]
        case .teal: return dark ? [Color(hex: 0x17454D), Color(hex: 0x225D65)] : [Color(hex: 0x184D57), Color(hex: 0x23656C)]
        case .sage: return dark ? [Color(hex: 0x34472A), Color(hex: 0x4C5E36)] : [Color(hex: 0x40532F), Color(hex: 0x526437)]
        case .peach: return dark ? [Color(hex: 0x6F3C32), Color(hex: 0x8C4938)] : [Color(hex: 0x783D32), Color(hex: 0x984934)]
        case .sand: return dark ? [Color(hex: 0x59472A), Color(hex: 0x73582D)] : [Color(hex: 0x624D2C), Color(hex: 0x7B5B29)]
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

extension HomeSection {
    var tint: ThemeTint {
        switch self {
        case .accounts: return .mint
        case .investments: return .teal
        case .debts: return .peach
        case .assets: return .sand
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

/// Fondo de todas las pantallas: neutros suaves con un matiz verde discreto.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark

        ZStack {
            LinearGradient(
                colors: dark
                    ? [Color(hex: 0x101613), Color(hex: 0x17211C)]
                    : [Color(hex: 0xF6F8F5), Color(hex: 0xEEF3EF)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(hex: dark ? 0x386F56 : 0xA8CCB5, opacity: dark ? 0.14 : 0.1), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 760
            )
        }
        .ignoresSafeArea()
    }
}

/// Fondo translúcido de las filas de los formularios y listas.
struct RowBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        scheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.88)
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

extension View {
    /// Botón secundario de vidrio en forma de píldora.
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
}

/// Barra de cada pestaña: botones a los lados y, en medio, el total de la pantalla. Si no cabe en
/// una fila (iPhone o letra grande), el total va arriba y los botones abajo.
struct TabHeader<Leading: View, Trailing: View>: View {
    @Environment(\.l10n) private var t
    @Environment(\.textScale) private var scale
    @Environment(\.colorScheme) private var scheme
    let caption: String
    let amount: Double
    let leading: Leading
    let trailing: Trailing

    init(
        caption: String,
        amount: Double,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.caption = caption
        self.amount = amount
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                leading
                Spacer(minLength: 12)
                center
                Spacer(minLength: 12)
                trailing
            }
            VStack(spacing: 12) {
                center
                HStack(spacing: 10) {
                    leading
                    Spacer(minLength: 8)
                    trailing
                }
            }
            VStack(spacing: 10) {
                center
                HStack(spacing: 10) { leading }
                HStack(spacing: 10) { trailing }
            }
        }
        .foregroundStyle(foreground)
        .padding(14 * scale)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var center: some View {
        VStack(spacing: 2) {
            Text(caption)
                .appFont(.subheadline, weight: .bold)
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(foreground.opacity(0.65))
                .lineLimit(1)
            Text(t.money(amount))
                .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(foreground)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
    }

    /// El vidrio nativo puede heredar un color de etiqueta que no sigue la apariencia de la app.
    private var foreground: Color {
        Color(hex: scheme == .dark ? 0xF1F7F3 : 0x172B24)
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

/// Ícono dentro de un cuadrito redondeado con el color de su categoría. `filled` lo pone blanco
/// sobre el degradado, como en los menús.
struct IconTile: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.textScale) private var scale
    let systemImage: String
    let tint: ThemeTint
    var size: CGFloat = 34
    var filled = false

    var body: some View {
        let side = size * scale
        let shape = RoundedRectangle(cornerRadius: side * 0.3, style: .continuous)

        Image(systemName: systemImage)
            .font(.system(size: side * 0.46, weight: .semibold, design: .rounded))
            .foregroundStyle(filled ? Color.white : tint.solid(scheme))
            .frame(width: side, height: side)
            .background {
                if filled {
                    shape.fill(LinearGradient(colors: tint.gradient(scheme), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: tint.solid(scheme).opacity(0.35), radius: 6, y: 3)
                } else {
                    shape.fill(tint.solid(scheme).opacity(scheme == .dark ? 0.18 : 0.14))
                }
            }
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

/// Línea de saldo que sube y baja con `values`; si todos son iguales, queda recta a media altura.
struct Sparkline: View {
    let values: [Double]
    var color: Color = .white

    var body: some View {
        ZStack {
            SparklineShape(values: values, closed: true)
                .fill(LinearGradient(colors: [color.opacity(0.28), color.opacity(0)], startPoint: .top, endPoint: .bottom))
            SparklineShape(values: values, closed: false)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
    }
}

private struct SparklineShape: Shape {
    let values: [Double]
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }
        let low = values.min() ?? 0
        let range = (values.max() ?? 0) - low
        // Margen para que el trazo no se corte arriba ni abajo.
        let inset: CGFloat = 3
        let points = values.enumerated().map { index, value in
            CGPoint(
                x: rect.width * CGFloat(index) / CGFloat(values.count - 1),
                y: range > 0 ? inset + (rect.height - 2 * inset) * CGFloat(1 - (value - low) / range) : rect.height / 2
            )
        }

        var path = Path()
        path.move(to: points[0])
        // Curvas suaves que pasan por el punto medio entre cada par de puntos.
        for i in 1..<points.count {
            let mid = CGPoint(x: (points[i - 1].x + points[i].x) / 2, y: (points[i - 1].y + points[i].y) / 2)
            path.addQuadCurve(to: mid, control: points[i - 1])
        }
        path.addLine(to: points[points.count - 1])
        if closed {
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        }
        return path
    }
}
