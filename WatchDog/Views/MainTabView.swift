import SwiftUI

struct MainTabView: View {
    @State private var syncService = SyncService.shared
    @State private var dismissedError: String? = nil
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onSwitchTab: { selectedTab = $0 })
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ApplianceListView()
                .tabItem { Label("Appliances", systemImage: "refrigerator.fill") }
                .tag(1)

            ExpiryListView()
                .tabItem { Label("Expiry", systemImage: "clock.badge.exclamationmark") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color.accentTeal)
        .overlay(alignment: .top) {
            syncBanner
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: syncService.isSyncing)
                .animation(.easeInOut(duration: 0.2), value: syncService.syncErrorMessage)
        }
        .overlay(alignment: .top) {
            ErrorBannerHost()
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var syncBanner: some View {
        if syncService.isSyncing {
            BannerView(
                message: "Syncing…",
                tint: Color.accentTeal,
                background: Color.accentTealLight,
                showsSpinner: true
            )
        } else if let message = syncService.syncErrorMessage {
            BannerView(
                message: message,
                tint: .orange,
                background: Color.orange.opacity(0.18),
                showsSpinner: false
            )
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    if syncService.syncErrorMessage == message {
                        syncService.syncErrorMessage = nil
                    }
                }
            }
        }
    }
}

private struct BannerView: View {
    let message: String
    let tint: Color
    let background: Color
    let showsSpinner: Bool

    var body: some View {
        HStack(spacing: 8) {
            if showsSpinner {
                ProgressView()
                    .controlSize(.small)
                    .tint(tint)
            }
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(background)
    }
}

#Preview {
    MainTabView()
}
