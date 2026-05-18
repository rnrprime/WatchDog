import SwiftUI
import AVFoundation
import UIKit

/// Full-screen barcode scanner. Uses AVFoundation metadata output so the
/// detection is done by the OS — supports EAN-13/8, UPC-E, Code 128/39, QR.
/// On detection we pause capture, hit the product-lookup API, then either
/// auto-fill brand/model or fall back to manual entry.
struct BarcodeScannerView: View {
    let onResult: (_ brand: String?, _ model: String?) -> Void
    let onManualFallback: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var permission: AVAuthorizationStatus = CameraPermission.current
    @State private var phase: Phase = .scanning
    @State private var lastDetectedCode: String?

    private let windowSize = CGSize(width: 260, height: 260)

    enum Phase: Equatable {
        case scanning
        case lookingUp(code: String)
        case notFound(code: String)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch permission {
            case .authorized:
                cameraStack
            case .denied, .restricted:
                CameraPermissionDeniedView(onClose: cancel)
            case .notDetermined:
                ProgressView().tint(.white)
                    .task { await requestPermission() }
            @unknown default:
                CameraPermissionDeniedView(onClose: cancel)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var cameraStack: some View {
        ZStack {
            BarcodeCameraPreview(isPaused: phase != .scanning) { code in
                handleScan(code)
            }
            .ignoresSafeArea()

            ScannerOverlay(windowSize: windowSize, cornerRadius: 20, showSweepLine: true)

            VStack {
                topBar
                Spacer()
                instructionText
                Spacer().frame(height: 28)
                phaseFooter
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: cancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            .accessibilityLabel("Close scanner")
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var instructionText: some View {
        switch phase {
        case .scanning:
            Text("Center the barcode in the box")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.45)))
        case .lookingUp:
            HStack(spacing: 10) {
                ProgressView().tint(.white)
                Text("Looking up product…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.55)))
        case .notFound(let code):
            Text("Couldn't identify barcode \(code)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.orange.opacity(0.85)))
        }
    }

    @ViewBuilder
    private var phaseFooter: some View {
        switch phase {
        case .notFound:
            VStack(spacing: 10) {
                Button {
                    HapticsService.selection()
                    onManualFallback()
                    dismiss()
                } label: {
                    Text("Enter manually")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Capsule().fill(Color.accentTeal))
                }
                Button {
                    phase = .scanning
                    lastDetectedCode = nil
                } label: {
                    Text("Try another barcode")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        default:
            EmptyView()
        }
    }

    private func handleScan(_ code: String) {
        guard phase == .scanning, code != lastDetectedCode else { return }
        lastDetectedCode = code
        HapticsService.impact(.medium)
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .lookingUp(code: code)
        }
        Task {
            let product = await ProductLookupService.shared.lookup(code)
            await MainActor.run {
                if let product, product.brand != nil || product.model != nil {
                    HapticsService.success()
                    onResult(product.brand, product.model)
                    dismiss()
                } else {
                    HapticsService.warning()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        phase = .notFound(code: code)
                    }
                }
            }
        }
    }

    private func cancel() {
        onCancel()
        dismiss()
    }

    private func requestPermission() async {
        let granted = await CameraPermission.request()
        await MainActor.run {
            permission = granted ? .authorized : .denied
        }
    }
}

// MARK: - Camera bridge

private struct BarcodeCameraPreview: UIViewControllerRepresentable {
    let isPaused: Bool
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraController {
        BarcodeCameraController(onCode: onCode)
    }

    func updateUIViewController(_ controller: BarcodeCameraController, context: Context) {
        controller.setPaused(isPaused)
    }
}

private final class BarcodeCameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let onCode: (String) -> Void

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "watchdog.barcode.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isPaused: Bool = false

    init(onCode: @escaping (String) -> Void) {
        self.onCode = onCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back
                  ),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            let output = AVCaptureMetadataOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [
                    .ean13, .ean8, .upce, .code128, .code39, .qr
                ]
            }

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.view.bounds
                self.view.layer.addSublayer(preview)
                self.previewLayer = preview
            }
        }
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    // MARK: Metadata callback

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue
        else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isPaused else { return }
            self.onCode(value)
        }
    }
}
