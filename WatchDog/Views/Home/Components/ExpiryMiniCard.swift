import SwiftUI

struct ExpiryMiniCard: View {
    let item: UrgentItem
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                icon
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                DaysCountdownView(endDate: item.endDate, style: .compact)
            }
            .frame(width: 160, height: 120, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
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
