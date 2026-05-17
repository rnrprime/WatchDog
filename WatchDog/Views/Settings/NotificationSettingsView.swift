import SwiftUI
import UserNotifications
import UIKit

struct NotificationSettingsView: View {
    @State private var notifications = NotificationService.shared
    @State private var syncService = SyncService.shared
    @State private var pendingCount: Int = 0

    @AppStorage("warrantyReminder90") private var warrantyReminder90 = true
    @AppStorage("warrantyReminder30") private var warrantyReminder30 = true
    @AppStorage("warrantyReminder7") private var warrantyReminder7 = true
    @AppStorage("warrantyReminder1") private var warrantyReminder1 = true

    @AppStorage("expiryReminder30") private var expiryReminder30 = true
    @AppStorage("expiryReminder7") private var expiryReminder7 = true
    @AppStorage("expiryReminder1") private var expiryReminder1 = false

    var body: some View {
        List {
            statusSection
            warrantyDefaultsSection
            expiryDefaultsSection
            syncSection

            #if DEBUG
            debugSection
            #endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notifications.checkAuthorizationStatus()
            pendingCount = await notifications.pendingCount()
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section {
            switch notifications.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusValid)
                    Text("Notifications are on")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
            case .denied:
                Button {
                    openSystemSettings()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.statusExpired)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications are off")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(.label))
                            Text("Tap to open Settings")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            case .notDetermined:
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications not set up")
                            .font(.system(size: 16, weight: .medium))
                    }
                    Button {
                        Task { _ = await notifications.requestAuthorization() }
                    } label: {
                        Text("Turn on notifications")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Capsule().fill(Color.accentTeal))
                    }
                    .buttonStyle(.plain)
                }
            @unknown default:
                EmptyView()
            }
        }
    }

    private var warrantyDefaultsSection: some View {
        Section("Warranty reminders") {
            Toggle("90 days before", isOn: $warrantyReminder90).tint(Color.accentTeal)
            Toggle("30 days before", isOn: $warrantyReminder30).tint(Color.accentTeal)
            Toggle("7 days before", isOn: $warrantyReminder7).tint(Color.accentTeal)
            Toggle("1 day before", isOn: $warrantyReminder1).tint(Color.accentTeal)
        }
    }

    private var expiryDefaultsSection: some View {
        Section("Expiry reminders") {
            Toggle("30 days before", isOn: $expiryReminder30).tint(Color.accentTeal)
            Toggle("7 days before", isOn: $expiryReminder7).tint(Color.accentTeal)
            Toggle("1 day before", isOn: $expiryReminder1).tint(Color.accentTeal)
        }
    }

    private var syncSection: some View {
        Section("Sync") {
            HStack {
                Text("Last synced")
                Spacer()
                Text(syncService.lastSyncDate.map(formatted(_:)) ?? "Never")
                    .foregroundStyle(.secondary)
            }
            Button {
                Task { await syncService.syncPendingItems() }
            } label: {
                HStack {
                    Text("Force sync now")
                        .foregroundStyle(Color.accentTeal)
                    Spacer()
                    if syncService.isSyncing {
                        ProgressView()
                    }
                }
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            HStack {
                Text("Pending notifications")
                Spacer()
                Text("\(pendingCount)").foregroundStyle(.secondary)
            }

            Button("Refresh pending count") {
                Task { pendingCount = await notifications.pendingCount() }
            }
            .foregroundStyle(Color.accentTeal)

            Button("Test notification (5 seconds)") {
                notifications.scheduleTestNotification(in: 5)
            }
            .foregroundStyle(Color.accentTeal)

            Button(role: .destructive) {
                notifications.cancelAllReminders()
                Task { pendingCount = await notifications.pendingCount() }
            } label: {
                Text("Clear all pending notifications")
            }
        }
    }
    #endif

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }
}
