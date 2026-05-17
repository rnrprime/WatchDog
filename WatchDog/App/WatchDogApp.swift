import SwiftUI
import SwiftData

@main
struct WatchDogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var supabase = SupabaseService.shared

    let modelContainer: ModelContainer

    init() {
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
            fatalError("Failed to create ModelContainer: \(error)")
        }
        SyncService.shared.setup(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabase, supabase)
        }
        .modelContainer(modelContainer)
    }
}
