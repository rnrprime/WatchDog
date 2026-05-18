import SwiftUI
import AVFoundation
import UIKit

/// Shared full-screen scanner chrome:
/// - dark vignette around a transparent rectangular scan window
/// - animated teal corner brackets around the window
/// - optional sweeping scan line inside the window
struct ScannerOverlay: View {
    let windowSize: CGSize
    var cornerRadius: CGFloat = 16
    var showSweepLine: Bool = false

    @State private var pulse: CGFloat = 0
    @State private var sweep: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let bounds = proxy.size
            let window = CGRect(
                x: (bounds.width - windowSize.width) / 2,
                y: (bounds.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            )

            ZStack(alignment: .topLeading) {
                // Vignette
                Canvas { ctx, size in
                    var path = Path()
                    path.addRect(CGRect(origin: .zero, size: size))
                    path.addRoundedRect(
                        in: window,
                        cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
                    )
                    ctx.fill(
                        path,
                        with: .color(.black.opacity(0.55)),
                        style: FillStyle(eoFill: true)
                    )
                }
                .allowsHitTesting(false)

                // Window border (subtle)
                Path { p in
                    p.addRoundedRect(
                        in: window,
                        cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
                    )
                }
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .allowsHitTesting(false)

                // Corner brackets
                CornerBrackets(
                    rect: window,
                    cornerRadius: cornerRadius,
                    pulse: pulse
                )
                .stroke(Color.accentTeal, lineWidth: 3)
                .shadow(color: Color.accentTeal.opacity(0.5), radius: 4)
                .allowsHitTesting(false)

                // Sweep line
                if showSweepLine {
                    let lineY = window.minY + (window.height - 2) * sweep
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentTeal.opacity(0),
                                    Color.accentTeal,
                                    Color.accentTeal.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: window.width - 8, height: 2)
                        .position(x: window.midX, y: lineY)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
            if showSweepLine {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    sweep = 1
                }
            }
        }
    }
}

private struct CornerBrackets: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat
    var pulse: CGFloat

    var animatableData: CGFloat {
        get { pulse }
        set { pulse = newValue }
    }

    func path(in _: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 22 + (pulse * 4)
        let r = cornerRadius
        let minX = rect.minX, maxX = rect.maxX
        let minY = rect.minY, maxY = rect.maxY

        // Top-left
        path.move(to: CGPoint(x: minX, y: minY + r + length))
        path.addLine(to: CGPoint(x: minX, y: minY + r))
        path.addArc(
            center: CGPoint(x: minX + r, y: minY + r),
            radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.addLine(to: CGPoint(x: minX + r + length, y: minY))

        // Top-right
        path.move(to: CGPoint(x: maxX - r - length, y: minY))
        path.addLine(to: CGPoint(x: maxX - r, y: minY))
        path.addArc(
            center: CGPoint(x: maxX - r, y: minY + r),
            radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: maxX, y: minY + r + length))

        // Bottom-right
        path.move(to: CGPoint(x: maxX, y: maxY - r - length))
        path.addLine(to: CGPoint(x: maxX, y: maxY - r))
        path.addArc(
            center: CGPoint(x: maxX - r, y: maxY - r),
            radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: maxX - r - length, y: maxY))

        // Bottom-left
        path.move(to: CGPoint(x: minX + r + length, y: maxY))
        path.addLine(to: CGPoint(x: minX + r, y: maxY))
        path.addArc(
            center: CGPoint(x: minX + r, y: maxY - r),
            radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: minX, y: maxY - r - length))

        return path
    }
}

/// Renders when camera permission is denied / restricted. Non-blocking inline
/// card with a Settings deep-link.
struct CameraPermissionDeniedView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Camera access is off")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(.label))
            Text("Watchdog needs the camera to scan serial numbers and barcodes. You can turn it on in Settings.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Capsule().fill(Color.accentTeal))
                }
                Button("Cancel", action: onClose)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
            }
            .padding(.horizontal, 24)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

enum CameraPermission {
    @MainActor
    static var current: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
