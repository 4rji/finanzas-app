import SwiftUI
import SwiftData

@main
struct FinanzasApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Debt.self, InstallmentPlan.self,
                configurations: ModelConfiguration("Finanzas")
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
            .appLanguage()
            #if os(macOS)
            .frame(minWidth: 480, minHeight: 420)
            #endif
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 760, height: 600)
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .frame(width: 420)
                .appLanguage()
        }
        #endif
    }
}
