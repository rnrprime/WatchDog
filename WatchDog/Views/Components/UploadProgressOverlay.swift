import SwiftUI

struct UploadProgressOverlay: View {
    @State private var storage = StorageService.shared
    @State private var dismissedError: String? = nil

    var body: some View {
        VStack {
            banner
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.25), value: storage.isUploading)
        .animation(.easeInOut(duration: 0.25), value: storage.lastUploadError)
    }

    @ViewBuilder
    private var banner: some View {
        if storage.isUploading {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(Color.accentTeal)
                Text("Uploading…")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color.accentTealLight)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if let error = storage.lastUploadError, error != dismissedError {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Upload failed — tap to retry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.orange)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color.orange.opacity(0.18))
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if storage.lastUploadError == error {
                        dismissedError = error
                        storage.lastUploadError = nil
                    }
                }
            }
        }
    }
}
