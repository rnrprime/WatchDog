import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

struct Step4_Documents: View {
    @Bindable var viewModel: AddApplianceViewModel
    let onSkip: () -> Void

    @State private var showReceiptScanner: Bool = false
    @State private var showPDFPicker: Bool = false
    @State private var ocrResult: OCRResult? = nil
    @State private var capturedImage: UIImage? = nil
    @State private var showOCRConfirm: Bool = false
    @State private var showScannerUnsupported: Bool = false

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
                    title: receiptTitle,
                    subtitle: receiptSubtitle,
                    isAttached: viewModel.pendingReceiptImage != nil
                ) {
                    if VNDocumentCameraViewController.isSupported {
                        showReceiptScanner = true
                    } else {
                        showScannerUnsupported = true
                    }
                }
                DocumentCard(
                    icon: "book.fill",
                    title: manualTitle,
                    subtitle: manualSubtitle,
                    isAttached: viewModel.pendingManualPDF != nil
                ) {
                    showPDFPicker = true
                }
            }

            SecondaryButton(title: "Skip for now") {
                viewModel.skippedDocuments = true
                onSkip()
            }
        }
        .padding(24)
        .fullScreenCover(
            isPresented: $showReceiptScanner,
            onDismiss: {
                if ocrResult != nil && capturedImage != nil {
                    showOCRConfirm = true
                }
            }
        ) {
            ReceiptScannerView(
                onResult: { result, image in
                    ocrResult = result
                    capturedImage = image
                    showReceiptScanner = false
                },
                onCancel: {
                    ocrResult = nil
                    capturedImage = nil
                    showReceiptScanner = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(
            isPresented: $showOCRConfirm,
            onDismiss: {
                if showReceiptScanner == false {
                    ocrResult = nil
                    capturedImage = nil
                }
            }
        ) {
            if let result = ocrResult, let image = capturedImage {
                OCRConfirmView(
                    result: result,
                    image: image,
                    onConfirm: { date, price, brand in
                        if let date {
                            viewModel.purchaseDate = date
                        }
                        if let price, viewModel.purchasePrice.isEmpty {
                            viewModel.purchasePrice = "\(price)"
                        }
                        if let brand, viewModel.brand.isEmpty {
                            viewModel.brand = brand
                        }
                        viewModel.pendingReceiptImage = image
                        showOCRConfirm = false
                    },
                    onRetake: {
                        ocrResult = nil
                        capturedImage = nil
                        showOCRConfirm = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            showReceiptScanner = true
                        }
                    },
                    onEnterManually: {
                        showOCRConfirm = false
                    }
                )
            }
        }
        .sheet(isPresented: $showPDFPicker) {
            PDFFilePicker { url in
                guard let url else { return }
                if let data = try? Data(contentsOf: url) {
                    viewModel.pendingManualPDF = data
                    viewModel.pendingManualFileName = url.lastPathComponent
                }
            }
        }
        .alert("Scanning unavailable", isPresented: $showScannerUnsupported) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Receipt scanning isn't supported on this device.")
        }
    }

    private var receiptTitle: String {
        viewModel.pendingReceiptImage == nil ? "Add receipt" : "Receipt attached"
    }

    private var receiptSubtitle: String {
        viewModel.pendingReceiptImage == nil
            ? "Photo or PDF — we'll save it securely"
            : "Tap to replace"
    }

    private var manualTitle: String {
        viewModel.pendingManualPDF == nil ? "Add product manual" : "Manual attached"
    }

    private var manualSubtitle: String {
        if let name = viewModel.pendingManualFileName { return name }
        return "PDF or photo"
    }
}

private struct DocumentCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isAttached: Bool
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
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        if isAttached {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.statusValid)
                        }
                    }
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

struct PDFFilePicker: UIViewControllerRepresentable {
    let onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void

        init(onPick: @escaping (URL?) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else {
                onPick(nil)
                return
            }
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}
