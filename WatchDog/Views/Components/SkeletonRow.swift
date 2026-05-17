import SwiftUI

struct SkeletonRow: View {
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: proxy.size.width * 0.6, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: proxy.size.width * 0.4, height: 12)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(0..<5) { _ in
            SkeletonRow()
            Divider()
        }
    }
}
