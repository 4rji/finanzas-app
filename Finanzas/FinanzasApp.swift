import SwiftUI
import SwiftData

@main
struct FinanzasApp: App {
    let container: ModelContainer

    init() {
        do {
            // Sincronización con iCloud APAGADA por ahora: los datos se quedan en cada dispositivo.
            // Para activarla (requiere cuenta de Apple Developer de pago):
            // 1. En el target, Build Settings: CODE_SIGN_ENTITLEMENTS = Config/Finanzas-iOS.entitlements,
            //    CODE_SIGN_ENTITLEMENTS[sdk=macosx*] = Config/Finanzas-macOS.entitlements e
            //    INFOPLIST_FILE[sdk=iphoneos*] / [sdk=iphonesimulator*] = Config/Info-iOS.plist.
            // 2. Cambiar `.none` por `.automatic` aquí abajo.
            container = try ModelContainer(
                for: Debt.self, InstallmentPlan.self, Account.self, RecurringIncome.self, Movement.self,
                configurations: ModelConfiguration("Finanzas", cloudKitDatabase: .none)
            )
        } catch {
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DashboardView()
            }
            .appPreferences()
            #if os(macOS)
            .frame(minWidth: 560, minHeight: 480)
            #endif
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 960, height: 720)
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .appPreferences()
        }
        #endif
    }
}
