import SwiftUI
import UIKit

struct DetailRow: View {
    let label: String
    let value: String?
    var systemImage: String? = nil
    var isCopyable: Bool = false
    var onCopy: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    if let value, !value.isEmpty {
                        Text(value)
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                    } else {
                        Text("Not set")
                            .font(.system(size: 17))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if isCopyable, let value, !value.isEmpty {
                    Button {
                        UIPasteboard.general.string = value
                        HapticsService.impact(.medium)
                        if label.localizedCaseInsensitiveContains("serial") {
                            AnalyticsService.shared.track(.serialNumberCopied)
                        }
                        BannerManager.shared.showSuccess("\(label) copied")
                        onCopy?(value)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.accentTeal)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy \(label)")
                    .accessibilityHint("Double tap to copy the \(label.lowercased()) to clipboard.")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
                .padding(.leading, 16)
        }
    }
}
