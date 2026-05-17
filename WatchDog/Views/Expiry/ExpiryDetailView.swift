import SwiftUI
import SwiftData

struct ExpiryDetailView: View {
    let item: ExpiryItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showRenewSheet = false
    @State private var showDeleteConfirm = false
    @State private var showRenewedToast = false
    @State private var remind30: Bool = true
    @State private var remind7: Bool = true
    @State private var remind1: Bool = true

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: .now, to: item.expiryDate).day ?? 0
    }

    private var isExpired: Bool { item.expiryDate < .now }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                countdownCard
                detailsSection
                remindersSection
                renewalHistorySection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        print("[ExpiryDetail] Edit")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
        .confirmDelete(isPresented: $showDeleteConfirm, itemName: item.name) {
            modelContext.delete(item)
            try? modelContext.save()
            dismiss()
        }
        .sheet(isPresented: $showRenewSheet) {
            RenewExpiryView(item: item) { _ in
                showToast()
            }
        }
        .overlay(alignment: .top) {
            if showRenewedToast {
                Text("Renewed! Reminders updated.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 16) {
            ExpiryCategoryIconView(category: item.category, size: 80)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)
                Text(categoryDisplayName(item.category))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentTealLight))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DaysCountdownView(endDate: item.expiryDate, style: .full)
                .font(.system(size: 48, weight: .semibold))

            Text(isExpired
                ? "Expired on \(formattedDate)"
                : "Expires on \(formattedDate)")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)

            PrimaryButton(title: "Renew") {
                showRenewSheet = true
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(countdownBackground)
        )
    }

    private var countdownBackground: Color {
        if isExpired { return Color.statusExpired.opacity(0.1) }
        if daysRemaining <= 7 { return Color.orange.opacity(0.1) }
        if daysRemaining <= 30 { return Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.1) }
        return Color.accentTealLight
    }

    @ViewBuilder
    private var detailsSection: some View {
        if hasDetails {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Details")
                VStack(alignment: .leading, spacing: 12) {
                    if let notes = item.notes, !notes.isEmpty {
                        detailRow(label: "Notes", value: notes)
                    }
                    if item.isRecurring, let days = item.recurrenceIntervalDays {
                        detailRow(label: "Recurs every", value: "\(days) days")
                    }
                    if let quantity = item.quantity {
                        let qtyText = "\(quantity)\(item.unit.map { " \($0)" } ?? "")"
                        detailRow(label: "Quantity", value: qtyText)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    private var hasDetails: Bool {
        (item.notes?.isEmpty == false) || item.isRecurring || item.quantity != nil
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Reminders")
            VStack(spacing: 0) {
                reminderToggle(label: "30 days before", binding: $remind30)
                divider
                reminderToggle(label: "7 days before", binding: $remind7)
                divider
                reminderToggle(label: "1 day before", binding: $remind1)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var renewalHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Renewal history")
            Text("No renewals yet")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))
        }
    }

    private func reminderToggle(label: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Color(.label))
        }
        .tint(Color.accentTeal)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private var formattedDate: String {
        item.expiryDate.formatted(.dateTime.month(.wide).day().year())
    }

    private func categoryDisplayName(_ c: ExpiryCategory) -> String {
        switch c {
        case .document: "Document"
        case .medication: "Medication"
        case .food: "Food"
        case .subscription: "Subscription"
        case .insurance: "Insurance"
        case .vehicle: "Vehicle"
        case .other: "Other"
        }
    }

    private func showToast() {
        withAnimation(.spring(duration: 0.3)) { showRenewedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.spring(duration: 0.3)) { showRenewedToast = false }
        }
    }
}
