import SwiftUI

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"

    init(_ title: String, action: (() -> Void)? = nil, actionLabel: String = "See all") {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.05)
                .foregroundStyle(.secondary)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader("Recent warranties")
        SectionHeader("Expiring soon", action: {})
        SectionHeader("Documents", action: {}, actionLabel: "View all")
    }
    .padding()
}
