import SwiftUI

/// Top-anchored banner that observes `BannerManager.shared`. Attach as an
/// overlay on the root view (see MainTabView). Auto-dismisses based on the
/// item's `autoDismissAfter`; tap to dismiss manually.
struct ErrorBannerHost: View {
    @State private var manager = BannerManager.shared

    var body: some View {
        VStack {
            if let item = manager.current {
                BannerCard(item: item) { manager.dismiss() }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: manager.current?.id)
    }
}

struct BannerCard: View {
    let item: BannerItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: item.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.type.tint)
                    .accessibilityHidden(true)
                Text(item.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.type.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(item.type.tint.opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.message). Double tap to dismiss.")
    }
}
