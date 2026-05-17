import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ApplianceListView()
                .tabItem { Label("Appliances", systemImage: "refrigerator.fill") }

            ExpiryListView()
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
