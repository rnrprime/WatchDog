import SwiftUI

struct NotificationPermissionView: View {
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 8)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80, weight: .regular))
                .foregroundStyle(Color.accentTeal)

            VStack(spacing: 10) {
                Text("Stay on top of expiry dates")
                    .font(.system(size: 22, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(.label))

                Text("We'll remind you before warranties and important documents expire — never get caught off guard.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            VStack(alignment: .leading, spacing: 10) {
                bulletRow("90, 30, and 7 days before warranty expiry")
                bulletRow("Reminders for passports, medications, and more")
                bulletRow("No spam — only what you've asked us to track")
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 8) {
                PrimaryButton(title: "Turn on reminders") {
                    onAccept()
                }
                Button("Maybe later", action: onSkip)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 24)
        .background(Color(.systemBackground))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentTeal)
                .font(.system(size: 16, weight: .semibold))
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
}
