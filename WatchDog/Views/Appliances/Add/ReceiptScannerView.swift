import SwiftUI
import UIKit
import VisionKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    let onResult: (OCRResult, UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onResult: (OCRResult, UIImage) -> Void
        let onCancel: () -> Void

        init(
            onResult: @escaping (OCRResult, UIImage) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onResult = onResult
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            let image = scan.imageOfPage(at: 0)
            Task {
                let result = await OCRService.shared.processReceipt(image: image)
                await MainActor.run {
                    onResult(result, image)
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            #if DEBUG
            print("[Scanner] failed: \(error)")
            #endif
            onCancel()
        }
    }
}
