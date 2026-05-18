import SwiftUI

/// Pure content row — the tap target is provided by the parent
/// `NavigationLink`. Do not wrap in a Button here.
struct RecentRowView: View {
    let item: RecentItem
    var showsDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                icon
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .contentShape(Rectangle())

            if showsDivider {
                Rectangle()
                    .fill(Color(.separator).opacity(0.6))
                    .frame(height: 0.5)
                    .padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .appliance(let appliance):
            CategoryIconView(category: appliance.category, size: 40)
        case .expiry(let expiryItem):
            ExpiryCategoryIconView(category: expiryItem.category, size: 40)
        }
    }

    private var subtitle: String {
        let typeLabel: String
        switch item {
        case .appliance: typeLabel = "Appliance"
        case .expiry: typeLabel = "Expiry item"
        }
        return "\(typeLabel) • \(addedLabel)"
    }

    private var addedLabel: String {
        let days = Calendar.current.dateComponents([.day], from: item.createdAt, to: .now).day ?? 0
        if days == 0 { return "added today" }
        if days == 1 { return "added yesterday" }
        return "added \(days) days ago"
    }
}
