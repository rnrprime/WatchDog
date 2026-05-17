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

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
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
