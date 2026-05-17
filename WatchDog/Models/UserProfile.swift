import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String?
    var avatarURL: String?
    var subscriptionTier: SubscriptionTier = SubscriptionTier.free
    var createdAt: Date = Date.now

    init(
        id: UUID,
        displayName: String? = nil,
        avatarURL: String? = nil,
        subscriptionTier: SubscriptionTier = .free
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.subscriptionTier = subscriptionTier
    }
}
