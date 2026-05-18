import Foundation
import SwiftUI

enum BannerType: Equatable {
    case error
    case warning
    case info
    case success

    var tint: Color {
        switch self {
        case .error: Color.statusExpired
        case .warning: Color.orange
        case .info: Color.accentTeal
        case .success: Color.green
        }
    }

    var background: Color {
        switch self {
        case .error: Color.red.opacity(0.15)
        case .warning: Color.orange.opacity(0.18)
        case .info: Color.accentTealLight
        case .success: Color.green.opacity(0.18)
        }
    }

    var icon: String {
        switch self {
        case .error: "exclamationmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        }
    }
}

struct BannerItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: BannerType
    let autoDismissAfter: TimeInterval?
}

@Observable
@MainActor
final class BannerManager {
    static let shared = BannerManager()

    var current: BannerItem?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, type: BannerType = .info, autoDismissAfter: TimeInterval? = 4.0) {
        let item = BannerItem(message: message, type: type, autoDismissAfter: autoDismissAfter)
        self.current = item

        dismissTask?.cancel()
        if let interval = autoDismissAfter {
            dismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                if self?.current?.id == item.id {
                    self?.current = nil
                }
            }
        }
    }

    func showError(_ message: String) {
        HapticsService.error()
        show(message, type: .error)
    }

    func showWarning(_ message: String) {
        HapticsService.warning()
        show(message, type: .warning, autoDismissAfter: 4.0)
    }

    func showInfo(_ message: String) {
        show(message, type: .info)
    }

    func showSuccess(_ message: String) {
        HapticsService.success()
        show(message, type: .success, autoDismissAfter: 3.0)
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}
