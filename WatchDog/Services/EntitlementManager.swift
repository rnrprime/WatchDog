import Foundation

enum PaywallTrigger: Identifiable, Equatable, Hashable {
    case applianceLimitReached
    case ocrAttempted
    case cloudBackupAttempted
    case advancedExpiryCategory

    var id: String {
        switch self {
        case .applianceLimitReached: "applianceLimitReached"
        case .ocrAttempted: "ocrAttempted"
        case .cloudBackupAttempted: "cloudBackupAttempted"
        case .advancedExpiryCategory: "advancedExpiryCategory"
        }
    }

    var headline: String {
        switch self {
        case .applianceLimitReached:
            "You've added 5 appliances"
        case .ocrAttempted:
            "Save time with smart scanning"
        case .cloudBackupAttempted:
            "Keep your data safe in the cloud"
        case .advancedExpiryCategory:
            "Track everything that expires"
        }
    }

    var subheadline: String {
        switch self {
        case .applianceLimitReached:
            "Unlock unlimited appliances and more with Pro"
        case .ocrAttempted:
            "Auto-fill purchase details from any receipt — only on Pro"
        case .cloudBackupAttempted:
            "Sync across devices and never lose a warranty — go Pro"
        case .advancedExpiryCategory:
            "Unlock all categories — passports, medications, subscriptions, and more"
        }
    }
}

@Observable
@MainActor
final class EntitlementManager {
    static let shared = EntitlementManager()

    /// Set this to non-nil from anywhere to present the paywall sheet.
    var paywallTrigger: PaywallTrigger?

    static let freeApplianceLimit = 5

    private init() {}

    var isPro: Bool { RevenueCatService.shared.isPro }

    var applianceLimit: Int { isPro ? .max : Self.freeApplianceLimit }

    var canUseOCR: Bool {
        // v1.0: OCR is free as a wow feature.
        // Flip to `isPro` to gate it later.
        true
    }

    var canUseCloudBackup: Bool { isPro }

    var canUseExpiryCategoriesBeyondBasic: Bool {
        // v1.0: all categories are free. Placeholder for future gating.
        true
    }

    /// Returns `true` if the user can add another appliance.
    /// If `false`, also sets `paywallTrigger = .applianceLimitReached` to
    /// trigger the paywall presentation in observing views.
    @discardableResult
    func checkApplianceLimit(currentCount: Int) -> Bool {
        if currentCount < applianceLimit { return true }
        paywallTrigger = .applianceLimitReached
        return false
    }

    func clearTrigger() {
        paywallTrigger = nil
    }
}
