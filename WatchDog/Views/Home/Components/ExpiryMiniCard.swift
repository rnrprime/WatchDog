import SwiftUI

/// Pure content card — tap is provided by parent NavigationLink.
struct ExpiryMiniCard: View {
    let item: UrgentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                icon
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                DaysCountdownView(endDate: item.endDate, style: .compact)
            }
        }
        .frame(width: 168, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .appliance(let appliance, _):
            CategoryIconView(category: appliance.category, size: 40)
        case .expiry(let expiryItem):
            ExpiryCategoryIconView(category: expiryItem.category, size: 40)
        }
    }
}
