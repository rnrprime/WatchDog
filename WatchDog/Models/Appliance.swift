import Foundation
import SwiftData

@Model
final class Appliance {
    var id: UUID = UUID()
    var supabaseId: UUID?
    var name: String = ""
    var brand: String?
    var model: String?
    var serialNumber: String?
    var category: ApplianceCategory = ApplianceCategory.other
    var purchaseDate: Date?
    var purchasePrice: Decimal?
    var store: String?
    var notes: String?
    var photoURL: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var pendingSync: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Warranty.appliance)
    var warranties: [Warranty] = []

    init(
        name: String,
        brand: String? = nil,
        model: String? = nil,
        serialNumber: String? = nil,
        category: ApplianceCategory = .other,
        purchaseDate: Date? = nil,
        purchasePrice: Decimal? = nil,
        store: String? = nil,
        notes: String? = nil,
        photoURL: String? = nil
    ) {
        self.name = name
        self.brand = brand
        self.model = model
        self.serialNumber = serialNumber
        self.category = category
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.store = store
        self.notes = notes
        self.photoURL = photoURL
    }
}
