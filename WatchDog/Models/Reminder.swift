import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID = UUID()
    var supabaseId: UUID?
    var entityType: String = ""
    var entityId: UUID = UUID()
    var remindAt: Date = Date.distantPast
    var channels: [String] = ["push"]
    var status: ReminderStatus = ReminderStatus.pending
    var createdAt: Date = Date.now

    init(
        entityType: String,
        entityId: UUID,
        remindAt: Date,
        channels: [String] = ["push"],
        status: ReminderStatus = .pending
    ) {
        self.entityType = entityType
        self.entityId = entityId
        self.remindAt = remindAt
        self.channels = channels
        self.status = status
    }
}
