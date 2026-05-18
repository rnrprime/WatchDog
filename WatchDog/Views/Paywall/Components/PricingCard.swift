import SwiftUI
import UIKit

struct PricingCard: View {
    let tier: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    init(
        tier: String,
        price: String,
        period: String,
        badge: String? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.tier = tier
        self.price = price
        self.period = period
        self.badge = badge
        self.isSelected = isSelected
        self.onTap = onTap
    }

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            onTap()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Text(tier.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.05)
                        .foregroundStyle(.secondary)
                    Text(price)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(period)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.accentTeal : Color(.separator),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )

                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentTeal))
                        .offset(x: -10, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
