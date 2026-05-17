import Foundation
import SwiftData

@Model
final class ExpiryItem {
    var id: UUID = UUID()
    var supabaseId: UUID?
    var name: String = ""
    var category: ExpiryCategory = ExpiryCategory.other
    var expiryDate: Date = Date.distantPast
    var quantity: Decimal?
    var unit: String?
    var notes: String?
    var isRecurring: Bool = false
    var recurrenceIntervalDays: Int?
    var photoURL: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var pendingSync: Bool = false

    init(
        name: String,
        category: ExpiryCategory = .other,
        expiryDate: Date,
        quantity: Decimal? = nil,
        unit: String? = nil,
        notes: String? = nil,
        isRecurring: Bool = false,
        recurrenceIntervalDays: Int? = nil,
        photoURL: String? = nil
    ) {
        self.name = name
        self.category = category
        self.expiryDate = expiryDate
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.isRecurring = isRecurring
        self.recurrenceIntervalDays = recurrenceIntervalDays
        self.photoURL = photoURL
    }
}
