import SwiftUI

struct StatusBadge: View {
    let daysRemaining: Int?

    private var label: String {
        guard let days = daysRemaining else { return "No date" }
        if days < 0 { return "Expired" }
        if days <= 30 { return "Expiring" }
        if days <= 90 { return "Soon" }
        return "Valid"
    }

    private var color: Color {
        guard let days = daysRemaining else { return Color(.systemGray) }
        if days < 0 { return .statusExpired }
        if days <= 30 { return .statusExpiring }
        if days <= 90 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        return .statusValid
    }

    private var accessibilityDescription: String {
        guard let days = daysRemaining else { return "No expiration date" }
        if days < 0 { return "Expired \(Swift.abs(days)) days ago" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days) days"
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
            .animation(.easeInOut(duration: 0.25), value: color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(daysRemaining: nil)
        StatusBadge(daysRemaining: -5)
        StatusBadge(daysRemaining: 14)
        StatusBadge(daysRemaining: 60)
        StatusBadge(daysRemaining: 200)
    }
    .padding()
}
