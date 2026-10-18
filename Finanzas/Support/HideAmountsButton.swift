import SwiftUI

/// Botón del ojo para ocultar o mostrar los saldos. Se guarda en `L10n.hidesAmountsKey`, así que
/// cambia todas las pantallas a la vez.
struct HideAmountsButton: View {
    @Environment(\.l10n) private var t
    @AppStorage(L10n.hidesAmountsKey) private var hidesAmounts = false

    var body: some View {
        Button {
            hidesAmounts.toggle()
        } label: {
            Label(hidesAmounts ? t.showAmounts : t.hideAmounts, systemImage: hidesAmounts ? "eye" : "eye.slash")
        }
    }
}

extension View {
    /// Agrega el botón del ojo a la barra de la pantalla.
    func hideAmountsToolbar() -> some View {
        toolbar {
            ToolbarItem(placement: .primaryAction) {
                HideAmountsButton()
            }
        }
    }
}
