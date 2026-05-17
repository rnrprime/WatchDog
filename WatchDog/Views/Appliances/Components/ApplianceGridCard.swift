import SwiftUI

struct ApplianceGridCard: View {
    let appliance: Appliance
    var onTap: () -> Void = {}

    private var daysRemaining: Int? {
        guard let end = appliance.warranties.map(\.endDate).min() else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: end).day
    }

    var body: some View {
        VStack(spacing: 12) {
            CategoryIconView(category: appliance.category, size: 56)

            Text(appliance.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.label))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            StatusBadge(daysRemaining: daysRemaining)
        }
        .padding(16)
        .frame(width: 170, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
