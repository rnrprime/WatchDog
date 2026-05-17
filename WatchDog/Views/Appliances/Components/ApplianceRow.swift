import SwiftUI

struct ApplianceRow: View {
    let appliance: Appliance
    var onTap: () -> Void = {}
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    private var earliestWarrantyEndDate: Date? {
        appliance.warranties.map(\.endDate).min()
    }

    private var daysRemaining: Int? {
        guard let end = earliestWarrantyEndDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: end).day
    }

    private var subtitle: String {
        let brand = appliance.brand?.isEmpty == false ? appliance.brand! : "Brand unknown"
        if let model = appliance.model, !model.isEmpty {
            return "\(brand) · \(model)"
        }
        return brand
    }

    private var warrantyText: String {
        guard let days = daysRemaining else { return "No warranty" }
        if days < 0 { return "Expired" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }

    private var warrantyTextColor: Color {
        guard let days = daysRemaining else { return .secondary }
        if days < 0 { return Color.statusExpired }
        if days <= 30 { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: appliance.category, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(appliance.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(warrantyText)
                    .font(.system(size: 13))
                    .foregroundStyle(warrantyTextColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(daysRemaining: daysRemaining)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .frame(minHeight: 70)
        .contentShape(Rectangle())
        .background(Color(.systemBackground))
    }
}
