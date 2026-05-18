import SwiftUI

struct PlanBadge: View {
    let tier: SubscriptionTier

    private var label: String {
        switch tier {
        case .free: "FREE"
        case .pro: "PRO"
        case .family: "FAMILY"
        }
    }

    private var background: Color {
        switch tier {
        case .free: Color(.tertiarySystemFill)
        case .pro: Color.accentTeal
        case .family: Color.purple
        }
    }

    private var foreground: Color {
        switch tier {
        case .free: Color(.secondaryLabel)
        case .pro, .family: .white
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if tier == .pro {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9, weight: .bold))
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(background))
    }
}
