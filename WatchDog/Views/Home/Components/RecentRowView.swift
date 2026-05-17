import SwiftUI

struct RecentRowView: View {
    let item: RecentItem
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    icon
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .lineLimit(1)
                        Text(addedLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(minHeight: 60)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
            }
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .appliance(let appliance):
            CategoryIconView(category: appliance.category, size: 44)
        case .expiry(let expiryItem):
            ExpiryCategoryIconView(category: expiryItem.category, size: 44)
        }
    }

    private var addedLabel: String {
        let days = Calendar.current.dateComponents([.day], from: item.createdAt, to: .now).day ?? 0
        if days == 0 { return "Added today" }
        if days == 1 { return "Added yesterday" }
        return "Added \(days) days ago"
    }
}
