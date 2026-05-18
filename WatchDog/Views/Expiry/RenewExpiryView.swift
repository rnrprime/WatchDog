import SwiftUI
import SwiftData
import UIKit

struct RenewExpiryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: ExpiryItem
    let onConfirm: (Date) -> Void

    @State private var newDate: Date
    @State private var isSaving = false

    init(item: ExpiryItem, onConfirm: @escaping (Date) -> Void) {
        self.item = item
        self.onConfirm = onConfirm
        let defaultDate: Date = {
            if item.isRecurring, let days = item.recurrenceIntervalDays {
                return Calendar.current.date(byAdding: .day, value: days, to: item.expiryDate)
                    ?? Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
            }
            return Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
        }()
        self._newDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Renew \(item.name)")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        Text("When does the new one expire?")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    DatePicker(
                        "",
                        selection: $newDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .tint(Color.accentTeal)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )

                    renewalHistorySection

                    PrimaryButton(
                        title: "Confirm renewal",
                        isLoading: isSaving
                    ) {
                        performRenewal()
                    }
                    .disabled(isSaving)
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Renew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentTeal)
                        .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var renewalHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RENEWAL HISTORY")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.05)
                .foregroundStyle(.secondary)
            Text("First renewal")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    private func performRenewal() {
        isSaving = true
        let chosenDate = newDate
        item.expiryDate = chosenDate
        item.updatedAt = .now
        item.pendingSync = true
        try? modelContext.save()
        HapticsService.success()
        AnalyticsService.shared.track(
            .expiryItemRenewed(category: item.category.rawValue)
        )

        NotificationService.shared.cancelReminders(entityId: item.id)
        if NotificationService.shared.authorizationStatus == .authorized {
            let defaults = UserDefaults.standard
            var days: [Int] = []
            if defaults.object(forKey: "expiryReminder30") as? Bool ?? true { days.append(30) }
            if defaults.object(forKey: "expiryReminder7") as? Bool ?? true { days.append(7) }
            if defaults.object(forKey: "expiryReminder1") as? Bool ?? false { days.append(1) }
            if !days.isEmpty {
                NotificationService.shared.scheduleExpiryReminders(for: item, reminderDays: days)
            }
        }

        Task { await SyncService.shared.syncExpiryItem(item) }

        onConfirm(chosenDate)
        dismiss()
    }
}
