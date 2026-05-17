import Foundation

enum ApplianceCategory: String, Codable, CaseIterable, Sendable {
    case kitchen, laundry, electronics, hvac, outdoor, other
}

enum WarrantyType: String, Codable, CaseIterable, Sendable {
    case manufacturer, extended, both
}

enum ExpiryCategory: String, Codable, CaseIterable, Sendable {
    case document, medication, food, subscription, insurance, vehicle, other
}

enum DocType: String, Codable, CaseIterable, Sendable {
    case receipt, manual, photo, other
}

enum ReminderStatus: String, Codable, CaseIterable, Sendable {
    case pending, sent, dismissed
}

enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free, pro, family
}
