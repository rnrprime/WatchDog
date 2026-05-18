import Foundation

/// All product events the app emits. Each case has a stable snake_case name
/// (analytics events live forever) and a set of default properties pulled from
/// the case's associated value.
///
/// Extend by adding cases — never rename existing ones.
enum AnalyticsEvent {
    // Onboarding & auth
    case onboardingStarted
    case onboardingCompleted
    case onboardingSkipped
    case authCompleted(method: String)

    // Appliance flow
    case applianceAddStarted
    case applianceAddCompleted(category: String)
    case applianceAddCancelled(atStep: Int)
    case applianceDetailViewed
    case serialNumberCopied

    // Expiry flow
    case expiryItemAddCompleted(category: String)
    case expiryItemRenewed(category: String)

    // OCR & documents
    case ocrScanAttempted
    case ocrScanSucceeded(confidence: Double)
    case documentUploaded(type: String)

    // Paywall & subscription
    case paywallViewed(trigger: String)
    case subscriptionPurchased(plan: String)
    case subscriptionRestored

    // Misc engagement
    case reminderNotificationTapped(entityType: String)
    case settingsOpened
    case dataExported

    var name: String {
        switch self {
        case .onboardingStarted: "onboarding_started"
        case .onboardingCompleted: "onboarding_completed"
        case .onboardingSkipped: "onboarding_skipped"
        case .authCompleted: "auth_completed"
        case .applianceAddStarted: "appliance_add_started"
        case .applianceAddCompleted: "appliance_add_completed"
        case .applianceAddCancelled: "appliance_add_cancelled"
        case .applianceDetailViewed: "appliance_detail_viewed"
        case .serialNumberCopied: "serial_number_copied"
        case .expiryItemAddCompleted: "expiry_item_add_completed"
        case .expiryItemRenewed: "expiry_item_renewed"
        case .ocrScanAttempted: "ocr_scan_attempted"
        case .ocrScanSucceeded: "ocr_scan_succeeded"
        case .documentUploaded: "document_uploaded"
        case .paywallViewed: "paywall_viewed"
        case .subscriptionPurchased: "subscription_purchased"
        case .subscriptionRestored: "subscription_restored"
        case .reminderNotificationTapped: "reminder_notification_tapped"
        case .settingsOpened: "settings_opened"
        case .dataExported: "data_exported"
        }
    }

    var defaultProperties: [String: Any] {
        switch self {
        case .authCompleted(let method): return ["method": method]
        case .applianceAddCompleted(let category): return ["category": category]
        case .applianceAddCancelled(let step): return ["step": step]
        case .expiryItemAddCompleted(let category): return ["category": category]
        case .expiryItemRenewed(let category): return ["category": category]
        case .ocrScanSucceeded(let confidence):
            return ["confidence": confidence]
        case .documentUploaded(let type): return ["type": type]
        case .paywallViewed(let trigger): return ["trigger": trigger]
        case .subscriptionPurchased(let plan): return ["plan": plan]
        case .reminderNotificationTapped(let entityType): return ["entity_type": entityType]
        default: return [:]
        }
    }
}
