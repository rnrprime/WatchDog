import SwiftUI
import SwiftData

@main
struct WatchDogApp: App {
    @State private var supabase = SupabaseService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabase, supabase)
        }
        .modelContainer(for: [
            Appliance.self,
            Warranty.self,
            ExpiryItem.self,
            Document.self,
            Reminder.self,
            UserProfile.self
        ])
    }
}
