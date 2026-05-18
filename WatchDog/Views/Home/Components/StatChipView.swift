import SwiftUI

/// Big primary stat card. Two of these fit side-by-side full width.
struct StatChipView: View {
    let label: String
    let count: Int
    let systemImage: String
    var subtitle: String? = nil
    var tint: Color = Color.accentTeal
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            HapticsService.selection()
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .padding(.bottom, 14)

                Text("\(count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color(.label))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: count)

                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .padding(.top, 2)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatChipView(
            label: "Appliances",
            count: 4,
            systemImage: "refrigerator.fill",
            subtitle: "3 warranties active"
        )
        StatChipView(
            label: "Expiring",
            count: 2,
            systemImage: "clock.fill",
            subtitle: "in 30 days",
            tint: .orange
        )
    }
    .padding()
}
