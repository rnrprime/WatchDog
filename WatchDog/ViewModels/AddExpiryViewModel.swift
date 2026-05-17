import Foundation
import SwiftData

@Observable
@MainActor
final class AddExpiryViewModel {
    var step: Int = 1
    var category: ExpiryCategory? = nil
    var name: String = ""
    var expiryDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    var notes: String = ""
    var isRecurring: Bool = false
    var recurrenceMonths: Int = 12

    var reminder30Days: Bool = true
    var reminder7Days: Bool = true
    var reminder1Day: Bool = false

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && category != nil
    }

    func placeholderName(for category: ExpiryCategory?) -> String {
        switch category {
        case .document: "Passport"
        case .medication: "Medication name"
        case .food: "Pantry item"
        case .subscription: "Service name"
        case .insurance: "Policy"
        case .vehicle: "Vehicle document"
        case .other, .none: "Item name"
        }
    }

    func applySmartDefaults(for category: ExpiryCategory) {
        self.category = category
        switch category {
        case .document:
            reminder30Days = true
            reminder7Days = true
            reminder1Day = false
            isRecurring = false
            recurrenceMonths = 120
        case .medication:
            reminder30Days = false
            reminder7Days = true
            reminder1Day = true
            isRecurring = false
            recurrenceMonths = 12
        case .food:
            reminder30Days = false
            reminder7Days = false
            reminder1Day = true
            isRecurring = false
            recurrenceMonths = 12
        case .subscription:
            reminder30Days = false
            reminder7Days = true
            reminder1Day = false
            isRecurring = true
            recurrenceMonths = 12
        case .insurance:
            reminder30Days = true
            reminder7Days = false
            reminder1Day = false
            isRecurring = true
            recurrenceMonths = 12
        case .vehicle:
            reminder30Days = true
            reminder7Days = true
            reminder1Day = false
            isRecurring = true
            recurrenceMonths = 12
        case .other:
            break
        }
    }

    @discardableResult
    func save(to context: ModelContext) async throws -> ExpiryItem {
        guard let category else {
            throw NSError(
                domain: "AddExpiry",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Category is required."]
            )
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(
                domain: "AddExpiry",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Name is required."]
            )
        }

        let item = ExpiryItem(
            name: trimmedName,
            category: category,
            expiryDate: expiryDate,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring,
            recurrenceIntervalDays: isRecurring ? recurrenceMonths * 30 : nil
        )
        item.pendingSync = true
        context.insert(item)
        try context.save()
        return item
    }
}
