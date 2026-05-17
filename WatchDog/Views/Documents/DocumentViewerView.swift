import SwiftUI
import PDFKit

struct DocumentViewerView: View {
    let document: Document
    var onDeleted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var signedURL: URL? = nil
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var showDeleteConfirm = false

    private var titleText: String {
        switch document.docType {
        case .receipt: "Receipt"
        case .manual: "Manual"
        case .photo: "Photo"
        case .other: "Document"
        }
    }

    private var isImage: Bool {
        document.mimeType?.hasPrefix("image") ?? false
    }

    private var isPDF: Bool {
        document.mimeType == "application/pdf"
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let signedURL {
                if isImage {
                    AsyncImageZoomable(url: signedURL)
                } else if isPDF {
                    PDFViewer(url: signedURL)
                } else {
                    unsupportedView
                }
            } else {
                errorView
            }
        }
        .background(Color.black)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let signedURL {
                    ShareLink(item: signedURL) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.accentTeal)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.accentTeal)
                }
            }
        }
        .confirmDelete(
            isPresented: $showDeleteConfirm,
            itemName: titleText
        ) {
            Task {
                try? await StorageService.shared.deleteDocument(document)
                onDeleted()
                dismiss()
            }
        }
        .task(id: document.id) {
            await fetchSignedURL()
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))
            Text(loadError ?? "Couldn't load this document")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
            Button("Try again") {
                Task { await fetchSignedURL() }
            }
            .foregroundStyle(Color.accentTeal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var unsupportedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))
            Text("Preview not supported")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fetchSignedURL() async {
        isLoading = true
        loadError = nil
        do {
            signedURL = try await StorageService.shared.getSignedURL(for: document)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

private struct AsyncImageZoomable: View {
    let url: URL
    @State private var loadedImage: UIImage? = nil

    var body: some View {
        Group {
            if let image = loadedImage {
                ZoomableScrollView(image: image)
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                loadedImage = UIImage(data: data)
            }
        } catch {
            #if DEBUG
            print("[DocumentViewer] image load failed: \(error)")
            #endif
        }
    }
}

private struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            Task.detached(priority: .userInitiated) {
                if let data = try? await URLSession.shared.data(from: url).0 {
                    if let document = PDFDocument(data: data) {
                        await MainActor.run {
                            uiView.document = document
                        }
                    }
                }
            }
        }
    }
}
