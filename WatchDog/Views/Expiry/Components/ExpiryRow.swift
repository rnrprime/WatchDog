import SwiftUI

struct ExpiryRow: View {
    let item: ExpiryItem
    var onTap: () -> Void = {}
    var onRenew: () -> Void = {}
    var onDelete: () -> Void = {}
    var onToggleReminder: () -> Void = {}

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: .now, to: item.expiryDate).day ?? 0
    }

    private var isExpired: Bool { item.expiryDate < .now }

    private var subtitle: String {
        var parts: [String] = [categoryDisplayName(item.category)]
        if item.isRecurring { parts.append("Recurring") }
        return parts.joined(separator: " · ")
    }

    private var dateLabel: String {
        let date = item.expiryDate.formatted(.dateTime.month(.abbreviated).day().year())
        return isExpired ? "Expired \(date)" : "Expires \(date)"
    }

    var body: some View {
        HStack(spacing: 12) {
            ExpiryCategoryIconView(category: item.category, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(dateLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                DaysCountdownView(endDate: item.expiryDate, style: .compact)
                Button {
                    onToggleReminder()
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minHeight: 70)
        .contentShape(Rectangle())
        .background(Color(.systemBackground))
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
}
