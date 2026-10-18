import SwiftUI
import SwiftData

@main
struct FinanzasApp: App {
    let container: ModelContainer

    init() {
        do {
            // `.automatic` sincroniza con el contenedor de iCloud de los entitlements, usando la
            // cuenta de iCloud del dispositivo. Sin cuenta de iCloud los datos se quedan locales.
            container = try ModelContainer(
                for: Debt.self, InstallmentPlan.self, Income.self,
                configurations: ModelConfiguration("Finanzas", cloudKitDatabase: .automatic)
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
