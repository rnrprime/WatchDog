import Foundation
import SwiftData

@Model
final class Warranty {
    var id: UUID = UUID()
    var supabaseId: UUID?
    var warrantyType: WarrantyType = WarrantyType.manufacturer
    var startDate: Date = Date.distantPast
    var endDate: Date = Date.distantPast
    var provider: String?
    var contactInfo: String?
    var notes: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var pendingSync: Bool = false

    var appliance: Appliance?

    init(
        warrantyType: WarrantyType,
        startDate: Date,
        endDate: Date,
        provider: String? = nil,
        contactInfo: String? = nil,
        notes: String? = nil,
        appliance: Appliance? = nil
    ) {
        self.warrantyType = warrantyType
        self.startDate = startDate
        self.endDate = endDate
        self.provider = provider
        self.contactInfo = contactInfo
        self.notes = notes
        self.appliance = appliance
    }
}
