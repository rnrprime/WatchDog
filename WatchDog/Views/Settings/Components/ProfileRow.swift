import SwiftUI

struct ProfileRow: View {
    let displayName: String?
    let email: String?
    let tier: SubscriptionTier
    let isGuest: Bool

    private var initials: String {
        guard let name = displayName?.trimmingCharacters(in: .whitespaces),
              !name.isEmpty
        else { return "" }
        let parts = name.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? ""
        let last = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentTealLight)
                    .frame(width: 44, height: 44)
                if isGuest || initials.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentTeal)
                } else {
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentTeal)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(primaryLine)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
                if let secondary = secondaryLine {
                    Text(secondary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                PlanBadge(tier: tier)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 4)
    }

    private var primaryLine: String {
        if isGuest { return "Guest user" }
        if let displayName, !displayName.isEmpty { return displayName }
        if let email, !email.isEmpty { return email }
        return "Signed in"
    }

    private var secondaryLine: String? {
        if isGuest { return "Sign in to sync your data" }
        return email
    }
}
