import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(.label))
                .padding(.top, 16)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 8)
                .padding(.horizontal, 32)
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(Capsule().fill(Color.accentTeal))
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    EmptyStateView(
        icon: "tray",
        title: "No appliances yet",
        subtitle: "Add your first appliance to start tracking warranties",
        actionLabel: "Add appliance",
        action: {}
    )
}
