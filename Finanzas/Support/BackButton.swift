import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Botón para regresar con el estilo de la app: flecha y el nombre de la pantalla anterior, en lugar
/// de la "<" sola del sistema.
private struct BackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.textScale) private var scale
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14 * scale, weight: .bold))
                            Text(title)
                                .appFont(.body, weight: .semibold)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(title)
                    .help(title)
                }
            }
    }
}

extension View {
    /// Cambia el botón de regresar del sistema por el de la app. `title` es la pantalla a la que regresa.
    func backButton(_ title: String) -> some View {
        modifier(BackButtonModifier(title: title))
    }
}

#if os(iOS)
/// Al ocultar el botón de regresar del sistema, iOS apaga el gesto de deslizar desde el borde para
/// regresar; esto lo vuelve a prender.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
#endif
