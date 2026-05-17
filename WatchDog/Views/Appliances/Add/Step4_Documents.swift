import SwiftUI

struct Step4_Documents: View {
    @Bindable var viewModel: AddApplianceViewModel
    let onSkip: () -> Void

    @State private var showComingSoon: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Documents (optional)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text("Add receipt and manual for safekeeping")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                DocumentCard(
                    icon: "doc.text.fill",
                    title: "Add receipt",
                    subtitle: "Photo or PDF — we'll save it securely"
                ) {
                    showComingSoon = true
                }
                DocumentCard(
                    icon: "book.fill",
                    title: "Add product manual",
                    subtitle: "PDF or photo"
                ) {
                    showComingSoon = true
                }
            }

            SecondaryButton(title: "Skip for now") {
                viewModel.skippedDocuments = true
                onSkip()
            }
        }
        .padding(24)
        .alert("Coming soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Document uploads aren't available yet.")
        }
    }
}

private struct DocumentCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentTealLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.accentTeal)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
