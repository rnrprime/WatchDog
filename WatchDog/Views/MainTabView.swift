import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Home — coming soon")
                    .navigationTitle("Home")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                Text("Appliances — coming soon")
                    .navigationTitle("Appliances")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Appliances", systemImage: "refrigerator.fill") }

            NavigationStack {
                Text("Expiry — coming soon")
                    .navigationTitle("Expiry")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Expiry", systemImage: "clock.badge.exclamationmark") }

            NavigationStack {
                Text("Settings — coming soon")
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.06, green: 0.43, blue: 0.34))
    }
}

#Preview {
    MainTabView()
}
