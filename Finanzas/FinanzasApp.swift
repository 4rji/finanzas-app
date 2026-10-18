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
            .appPreferences()
            .frame(minWidth: 560, minHeight: 480)
        }
        .modelContainer(container)
        .defaultSize(width: 960, height: 720)

        Settings {
            SettingsView()
                .appPreferences()
        }
    }
}
