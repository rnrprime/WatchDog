import SwiftUI

struct DocumentThumbnail: View {
    let document: Document
    var onTap: () -> Void = {}
    var onDelete: () -> Void = {}

    @State private var signedURL: URL? = nil
    @State private var isLoading: Bool = true

    private var isImage: Bool {
        document.mimeType?.hasPrefix("image") ?? false
    }

    private var isPDF: Bool {
        document.mimeType == "application/pdf"
    }

    private var displayLabel: String {
        switch document.docType {
        case .receipt: "Receipt"
        case .manual: "Manual"
        case .photo: "Photo"
        case .other: "Document"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                thumbnailArea
                    .frame(width: 100, height: 100)
                Text(displayLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .frame(height: 30)
            }
            .frame(width: 100, height: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("View", systemImage: "eye")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .task(id: document.id) {
            await loadSignedURL()
        }
    }

    @ViewBuilder
    private var thumbnailArea: some View {
        if isImage {
            if let url = signedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipped()
            } else if isLoading {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        } else if isPDF {
            ZStack {
                Color.accentTealLight
                Image(systemName: "doc.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
            }
        } else {
            ZStack {
                Color(.tertiarySystemBackground)
                Image(systemName: "doc")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadSignedURL() async {
        guard isImage else {
            isLoading = false
            return
        }
        signedURL = try? await StorageService.shared.getSignedURL(for: document)
        isLoading = false
    }
}
