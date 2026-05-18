import SwiftUI
import SwiftData
import UIKit
import Auth

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var appliances: [Appliance]
    @Query private var warranties: [Warranty]
    @Query private var expiryItems: [ExpiryItem]
    @Query private var documents: [Document]

    @State private var supabase = SupabaseService.shared
    @State private var revenueCat = RevenueCatService.shared
    @State private var entitlements = EntitlementManager.shared
    @State private var notifications = NotificationService.shared
    @State private var syncService = SyncService.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isGuestMode") private var isGuestMode = false

    @State private var showPaywall = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage: String = ""
    @State private var showSignOutConfirm = false
    @State private var showDeleteDataConfirm = false
    @State private var debugTapCount = 0
    @State private var showDebugMenu = false
    @State private var showExportSheet = false
    @State private var exportedURL: URL?

    private var displayName: String? {
        guard let metadata = supabase.currentUser?.userMetadata else { return nil }
        if let value = metadata["full_name"],
           case .string(let name) = value,
           !name.isEmpty {
            return name
        }
        if let value = metadata["name"],
           case .string(let name) = value,
           !name.isEmpty {
            return name
        }
        return nil
    }

    private var email: String? { supabase.currentUser?.email }

    private var tier: SubscriptionTier {
        revenueCat.isPro ? .pro : .free
    }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                subscriptionSection
                notificationsSection
                preferencesSection
                dataSection
                aboutSection
                if showDebugMenu { debugSection }
                signOutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                AnalyticsService.shared.track(.settingsOpened)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: nil) { showPaywall = false }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
            .confirmationDialog(
                "Sign out?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) { signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign back in to sync your data.")
            }
            .confirmationDialog(
                "Delete all data?",
                isPresented: $showDeleteDataConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) { clearAllLocalData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This wipes every appliance, warranty, expiry item, and document on this device. This can't be undone.")
            }
            .sheet(isPresented: $showExportSheet, onDismiss: {
                if let url = exportedURL { try? FileManager.default.removeItem(at: url) }
                exportedURL = nil
            }) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            Button {
                if isGuestMode {
                    signOut()  // routes back to auth so they can sign in
                }
            } label: {
                ProfileRow(
                    displayName: displayName,
                    email: email,
                    tier: tier,
                    isGuest: isGuestMode
                )
            }
            .buttonStyle(.plain)
            .disabled(!isGuestMode)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            if revenueCat.isPro {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.accentTeal)
                    Text("Watchdog Pro")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.accentTeal)
                        Text("Upgrade to Pro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.accentTeal)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                openURL("itms-apps://apps.apple.com/account/subscriptions")
            } label: {
                Label {
                    Text("Manage Subscription")
                } icon: {
                    Image(systemName: "creditcard")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Button {
                Task { await restorePurchases() }
            } label: {
                HStack {
                    Label {
                        Text("Restore Purchases")
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.accentTeal)
                    }
                    Spacer()
                    if revenueCat.isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .disabled(revenueCat.isLoading)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label {
                    Text("Notification settings")
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            NavigationLink {
                DefaultRemindersView()
            } label: {
                Label {
                    Text("Default reminder timing")
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            if revenueCat.isPro {
                Label {
                    Text("App icon")
                        .foregroundStyle(Color(.label))
                } icon: {
                    Image(systemName: "app.fill")
                        .foregroundStyle(Color.accentTeal)
                }
                // App icon picker can be wired up later
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                exportData()
            } label: {
                Label {
                    Text("Export my data")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Label {
                Text("Import data")
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showDeleteDataConfirm = true
            } label: {
                Label {
                    Text("Delete all data")
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            Button {
                openURL("itms-apps://itunes.apple.com/app/id000000000?action=write-review")
            } label: {
                Label {
                    Text("Rate Watchdog")
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            ShareLink(item: URL(string: "https://apps.apple.com/app/id000000000")!) {
                Label {
                    Text("Share with a friend")
                } icon: {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Button {
                openURL("https://watchdog.app/privacy")
            } label: {
                Label {
                    Text("Privacy Policy")
                } icon: {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Button {
                openURL("https://watchdog.app/terms")
            } label: {
                Label {
                    Text("Terms of Service")
                } icon: {
                    Image(systemName: "doc.text")
                        .foregroundStyle(Color.accentTeal)
                }
            }

            Button {
                debugTapCount += 1
                if debugTapCount >= 5 {
                    showDebugMenu = true
                }
            } label: {
                HStack {
                    Text("Version")
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Text(versionString)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Debug

    private var debugSection: some View {
        Section("Debug") {
            Button {
                DemoDataLoader.load(into: modelContext)
                BannerManager.shared.showSuccess("Loaded demo data for screenshots")
            } label: {
                Label {
                    Text("Load demo data for screenshots")
                } icon: {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.accentTeal)
                }
            }
            .foregroundStyle(Color.accentTeal)

            HStack {
                Text("Pending sync items")
                Spacer()
                Text("\(pendingSyncCount)")
                    .foregroundStyle(.secondary)
            }
            Button("Force sync now") {
                Task { await syncService.syncPendingItems() }
            }
            .foregroundStyle(Color.accentTeal)

            #if DEBUG
            Button("Test notification (5s)") {
                notifications.scheduleTestNotification(in: 5)
            }
            .foregroundStyle(Color.accentTeal)
            #endif

            Button("Reset onboarding") {
                hasCompletedOnboarding = false
                UserDefaults.standard.set(false, forKey: "isGuestMode")
            }
            .foregroundStyle(Color.accentTeal)

            Button("Reset RevenueCat") {
                Task {
                    await revenueCat.logout()
                    await revenueCat.fetchCustomerInfo()
                }
            }
            .foregroundStyle(Color.accentTeal)

            Button(role: .destructive) {
                showDeleteDataConfirm = true
            } label: {
                Text("Clear all data")
            }
        }
    }

    private var pendingSyncCount: Int {
        let applianceCount = appliances.filter { $0.pendingSync }.count
        let warrantyCount = warranties.filter { $0.pendingSync }.count
        let expiryCount = expiryItems.filter { $0.pendingSync }.count
        return applianceCount + warrantyCount + expiryCount
    }

    // MARK: - Sign out

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text(isGuestMode ? "Sign in" : "Sign out")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func restorePurchases() async {
        do {
            try await revenueCat.restorePurchases()
            restoreMessage = revenueCat.isPro
                ? "Pro features restored on this device."
                : "No active subscription found on this Apple ID."
        } catch {
            restoreMessage = error.localizedDescription
        }
        showRestoreAlert = true
    }

    private func signOut() {
        Task {
            try? await supabase.signOut()
            await revenueCat.logout()
            CrashReporter.setUser(id: nil, email: nil)
            AnalyticsService.shared.reset()
            hasCompletedOnboarding = false
            isGuestMode = false
        }
    }

    private func clearAllLocalData() {
        for appliance in appliances { modelContext.delete(appliance) }
        for warranty in warranties { modelContext.delete(warranty) }
        for item in expiryItems { modelContext.delete(item) }
        for doc in documents { modelContext.delete(doc) }
        try? modelContext.save()
    }

    private func exportData() {
        let snapshot = DataExportSnapshot(
            exportedAt: .now,
            appliances: appliances.map { ApplianceExport(from: $0) },
            warranties: warranties.map { WarrantyExport(from: $0) },
            expiryItems: expiryItems.map { ExpiryItemExport(from: $0) }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let filename = "watchdog-export-\(formatter.string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        exportedURL = url
        AnalyticsService.shared.track(.dataExported)
        showExportSheet = true
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Export snapshot

private struct DataExportSnapshot: Codable {
    let exportedAt: Date
    let appliances: [ApplianceExport]
    let warranties: [WarrantyExport]
    let expiryItems: [ExpiryItemExport]
}

private struct ApplianceExport: Codable {
    let id: UUID
    let name: String
    let brand: String?
    let model: String?
    let category: String
    let purchaseDate: Date?

    init(from a: Appliance) {
        self.id = a.id
        self.name = a.name
        self.brand = a.brand
        self.model = a.model
        self.category = a.category.rawValue
        self.purchaseDate = a.purchaseDate
    }
}

private struct WarrantyExport: Codable {
    let id: UUID
    let applianceId: UUID?
    let warrantyType: String
    let startDate: Date
    let endDate: Date
    let provider: String?

    init(from w: Warranty) {
        self.id = w.id
        self.applianceId = w.appliance?.id
        self.warrantyType = w.warrantyType.rawValue
        self.startDate = w.startDate
        self.endDate = w.endDate
        self.provider = w.provider
    }
}

private struct ExpiryItemExport: Codable {
    let id: UUID
    let name: String
    let category: String
    let expiryDate: Date

    init(from e: ExpiryItem) {
        self.id = e.id
        self.name = e.name
        self.category = e.category.rawValue
        self.expiryDate = e.expiryDate
    }
}

// MARK: - Share sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
