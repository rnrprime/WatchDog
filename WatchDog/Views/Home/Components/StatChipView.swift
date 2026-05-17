import SwiftUI

struct StatChipView: View {
    let label: String
    let count: Int
    let systemImage: String
    var tint: Color = Color.accentTeal
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                Text("\(count)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatChipView(label: "Appliances", count: 4, systemImage: "refrigerator.fill")
        StatChipView(label: "Warranties", count: 3, systemImage: "shield.fill")
        StatChipView(label: "Expiring", count: 2, systemImage: "clock.fill", tint: .orange)
    }
    .padding()
}
