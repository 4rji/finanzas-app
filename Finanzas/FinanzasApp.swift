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
            .frame(minWidth: 520, minHeight: 440)
        }
        .modelContainer(container)
        .defaultSize(width: 820, height: 620)

        Settings {
            SettingsView()
                .frame(width: 420)
                .appLanguage()
        }
    }
}
