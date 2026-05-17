import SwiftUI

struct ExpirySectionHeader: View {
    let section: ExpirySection
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(section.headerColor.opacity(0.6))
                .frame(height: 4)
            HStack(spacing: 6) {
                Text(section.displayName.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.05)
                    .foregroundStyle(section.headerColor)
                Text("(\(count))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}
