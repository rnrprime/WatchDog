import SwiftUI
import SwiftData

@main
struct WatchDogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var supabase = SupabaseService.shared

    let modelContainer: ModelContainer

    init() {
        // Bring up crash reporting first so any error during the rest of
        // launch is captured by Sentry.
        CrashReporter.configure()

        do {
            modelContainer = try ModelContainer(
                for: Appliance.self,
                Warranty.self,
                ExpiryItem.self,
                Document.self,
                Reminder.self,
                UserProfile.self
            )
        } catch {
            CrashReporter.logError(error, context: ["stage": "modelContainer.init"])
            fatalError("Failed to create ModelContainer: \(error)")
        }
        SyncService.shared.setup(container: modelContainer)
        _ = RevenueCatService.shared  // configure SDK at launch
        _ = AnalyticsService.shared   // configure PostHog at launch
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabase, supabase)
        }
        .modelContainer(modelContainer)
    }
}
