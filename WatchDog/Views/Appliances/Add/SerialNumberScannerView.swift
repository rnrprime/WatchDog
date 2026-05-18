import SwiftUI
import AVFoundation
import Vision
import UIKit

/// Full-screen live-text scanner. Streams the camera through Vision's
/// `VNRecognizeTextRequest`, scores candidates, and surfaces a high-confidence
/// match for confirmation.
struct SerialNumberScannerView: View {
    let onResult: (String) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var permission: AVAuthorizationStatus = CameraPermission.current
    @State private var detection: SerialDetectionEngine.Match?
    @State private var hasConfirmed = false
    @State private var torchOn = false
    @State private var autoConfirmTask: Task<Void, Never>?

    private let engine = SerialDetectionEngine()
    private let windowSize = CGSize(width: 300, height: 120)

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
        .onDisappear {
            autoConfirmTask?.cancel()
        }
    }

    @ViewBuilder
    private var cameraStack: some View {
        ZStack {
            SerialCameraPreview(
                engine: engine,
                torchOn: $torchOn,
                isFrozen: detection != nil
            ) { match in
                handleDetection(match)
            }
            .ignoresSafeArea()

            ScannerOverlay(windowSize: windowSize, cornerRadius: 16)

            VStack {
                topBar
                Spacer()
                instructionText
                Spacer().frame(height: 20)
                confirmationBar
            }
        }
    }

    private var topBar: some View {
        HStack {
            closeButton
            Spacer()
            torchButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var closeButton: some View {
        Button(action: cancel) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
        .accessibilityLabel("Close scanner")
    }

    private var torchButton: some View {
        Button {
            torchOn.toggle()
            HapticsService.selection()
        } label: {
            Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
        .accessibilityLabel(torchOn ? "Turn off flashlight" : "Turn on flashlight")
    }

    private var instructionText: some View {
        Text(detection == nil
             ? "Point at the serial number plate"
             : "Detected serial number")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.45)))
    }

    @ViewBuilder
    private var confirmationBar: some View {
        if let match = detection {
            VStack(spacing: 12) {
                Text(match.value)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentTeal))

                HStack(spacing: 12) {
                    Button(action: retake) {
                        Text("Retake")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                    }
                    Button {
                        confirm(match.value)
                    } label: {
                        Text("Use this")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Capsule().fill(Color.accentTeal))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 36)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func handleDetection(_ match: SerialDetectionEngine.Match) {
        guard !hasConfirmed, detection?.value != match.value else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            detection = match
        }
        HapticsService.impact(.medium)
        autoConfirmTask?.cancel()
        autoConfirmTask = Task { @MainActor [value = match.value] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled, !hasConfirmed, detection?.value == value else { return }
            confirm(value)
        }
    }

    private func confirm(_ value: String) {
        guard !hasConfirmed else { return }
        hasConfirmed = true
        autoConfirmTask?.cancel()
        HapticsService.success()
        onResult(value)
        dismiss()
    }

    private func retake() {
        autoConfirmTask?.cancel()
        engine.reset()
        withAnimation(.easeOut(duration: 0.2)) {
            detection = nil
        }
    }

    private func cancel() {
        autoConfirmTask?.cancel()
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

// MARK: - Detection engine

/// Frame-rate-throttled Vision text recogniser that hunts for serial-number-shaped
/// strings. Score-weighted across consecutive frames to avoid flickery picks.
/// Declared `nonisolated` so its delegate-driven `process` calls don't trip the
/// MainActor default that UIKit imposes on this file.
nonisolated final class SerialDetectionEngine: @unchecked Sendable {
    struct Match: Equatable {
        let value: String
        let confidence: Float
    }

    private var lastFrameTime: CFTimeInterval = 0
    private let minInterval: CFTimeInterval = 0.25  // 4 Hz cap
    private var consecutiveBest: String?
    private var consecutiveHits: Int = 0
    private let serialRegex: NSRegularExpression = {
        // 6–20 chars: alphanumeric, optional hyphen/underscore in the middle.
        let pattern = "^[A-Z0-9][A-Z0-9_-]{5,19}$"
        return (try? NSRegularExpression(pattern: pattern, options: [])) ?? .init()
    }()

    nonisolated func reset() {
        consecutiveBest = nil
        consecutiveHits = 0
        lastFrameTime = 0
    }

    /// Returns a match when a candidate has been seen with high confidence in
    /// at least 2 consecutive throttled frames. nil otherwise.
    nonisolated func process(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> Match? {
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= minInterval else { return nil }
        lastFrameTime = now

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        try? handler.perform([request])

        guard let observations = request.results else { return nil }

        var best: (String, Float)?
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let normalised = candidate.string
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard isSerial(normalised) else { continue }
            let weighted = candidate.confidence + heuristicBoost(for: normalised)
            if best == nil || weighted > best!.1 {
                best = (normalised, weighted)
            }
        }

        guard let (value, confidence) = best, confidence > 0.85 else {
            consecutiveHits = 0
            consecutiveBest = nil
            return nil
        }

        if consecutiveBest == value {
            consecutiveHits += 1
        } else {
            consecutiveBest = value
            consecutiveHits = 1
        }

        guard consecutiveHits >= 2 else { return nil }
        return Match(value: value, confidence: confidence)
    }

    private func isSerial(_ candidate: String) -> Bool {
        let range = NSRange(candidate.startIndex..., in: candidate)
        return serialRegex.firstMatch(in: candidate, options: [], range: range) != nil
    }

    /// Serial numbers tend to mix digits and letters; reward that.
    private func heuristicBoost(for candidate: String) -> Float {
        let hasDigit = candidate.contains(where: { $0.isNumber })
        let hasLetter = candidate.contains(where: { $0.isLetter })
        var boost: Float = 0
        if hasDigit { boost += 0.05 }
        if hasLetter { boost += 0.05 }
        if candidate.count >= 8 { boost += 0.05 }
        return boost
    }
}

// MARK: - Camera bridge

private struct SerialCameraPreview: UIViewControllerRepresentable {
    let engine: SerialDetectionEngine
    @Binding var torchOn: Bool
    let isFrozen: Bool
    let onDetect: (SerialDetectionEngine.Match) -> Void

    func makeUIViewController(context: Context) -> SerialCameraController {
        let controller = SerialCameraController(engine: engine, onDetect: onDetect)
        return controller
    }

    func updateUIViewController(_ controller: SerialCameraController, context: Context) {
        controller.setTorch(on: torchOn)
        controller.setPaused(isFrozen)
    }
}

private final class SerialCameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let engine: SerialDetectionEngine
    private let onDetect: (SerialDetectionEngine.Match) -> Void

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "watchdog.serial.session")
    private let videoQueue = DispatchQueue(label: "watchdog.serial.video")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var device: AVCaptureDevice?
    private var isPaused: Bool = false

    init(engine: SerialDetectionEngine, onDetect: @escaping (SerialDetectionEngine.Match) -> Void) {
        self.engine = engine
        self.onDetect = onDetect
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
            self.session.sessionPreset = .hd1280x720

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            self.device = device

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.videoQueue)
            if self.session.canAddOutput(output) { self.session.addOutput(output) }

            if let connection = output.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90  // portrait
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

    func setTorch(on: Bool) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
            } catch {
                // silently ignore — torch is best-effort
            }
        }
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    // MARK: Video frame callback

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let match = engine.process(
            pixelBuffer: pixelBuffer,
            orientation: .right
        ) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isPaused else { return }
            self.onDetect(match)
        }
    }
}
