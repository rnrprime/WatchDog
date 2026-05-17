import Foundation
import SwiftData
import UIKit

@Observable
@MainActor
final class AddApplianceViewModel {
    enum EntryMethod: String, CaseIterable, Identifiable {
        case scanSerial, scanBarcode, manual
        var id: String { rawValue }
    }

    enum DurationOption: String, CaseIterable, Identifiable {
        case oneYear, twoYears, threeYears, fiveYears, custom
        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .oneYear: "1 year"
            case .twoYears: "2 years"
            case .threeYears: "3 years"
            case .fiveYears: "5 years"
            case .custom: "Custom"
            }
        }

        var fixedMonths: Int? {
            switch self {
            case .oneYear: 12
            case .twoYears: 24
            case .threeYears: 36
            case .fiveYears: 60
            case .custom: nil
            }
        }
    }

    var currentStep: Int = 1
    let totalSteps: Int = 5

    var entryMethod: EntryMethod? = nil

    var name: String = ""
    var brand: String = ""
    var model: String = ""
    var serialNumber: String = ""
    var category: ApplianceCategory? = nil
    var purchaseDate: Date = .now {
        didSet { warrantyStartDate = purchaseDate }
    }
    var showAdvancedFields: Bool = false
    var purchasePrice: String = ""
    var store: String = ""
    var notes: String = ""

    var hasWarranty: Bool = true
    var warrantyType: WarrantyType = .manufacturer
    var warrantyStartDate: Date = .now
    var warrantyDurationOption: DurationOption = .oneYear
    var customDurationMonths: Int = 24
    var provider: String = ""
    var providerContact: String = ""

    var skippedDocuments: Bool = false

    var reminderNinetyDays: Bool = true
    var reminderThirtyDays: Bool = true
    var reminderSevenDays: Bool = true

    var canProceedFromStep2: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && category != nil
    }

    var canProceedFromStep3: Bool { true }

    var warrantyDurationMonths: Int {
        warrantyDurationOption.fixedMonths ?? customDurationMonths
    }

    var computedWarrantyEndDate: Date {
        Calendar.current.date(
            byAdding: .month,
            value: warrantyDurationMonths,
            to: warrantyStartDate
        ) ?? warrantyStartDate
    }

    var progressFraction: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var hasAnyEntry: Bool {
        !name.isEmpty || !brand.isEmpty || !model.isEmpty || !serialNumber.isEmpty
            || category != nil || !purchasePrice.isEmpty || !store.isEmpty || !notes.isEmpty
            || !provider.isEmpty || !providerContact.isEmpty
    }

    func nextStep() {
        guard currentStep < totalSteps else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 1 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentStep -= 1
    }

    func jumpToStep(_ step: Int) {
        guard (1...totalSteps).contains(step) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentStep = step
    }

    @discardableResult
    func save(to context: ModelContext) async throws -> Appliance {
        guard let category else {
            throw NSError(
                domain: "AddAppliance",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Category is required."]
            )
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(
                domain: "AddAppliance",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Name is required."]
            )
        }

        let priceDecimal: Decimal? = {
            let trimmed = purchasePrice.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            return Decimal(string: trimmed)
        }()

        let appliance = Appliance(
            name: trimmedName,
            brand: brand.isEmpty ? nil : brand,
            model: model.isEmpty ? nil : model,
            serialNumber: serialNumber.isEmpty ? nil : serialNumber,
            category: category,
            purchaseDate: purchaseDate,
            purchasePrice: priceDecimal,
            store: store.isEmpty ? nil : store,
            notes: notes.isEmpty ? nil : notes
        )
        appliance.pendingSync = true
        context.insert(appliance)

        if hasWarranty {
            let warranty = Warranty(
                warrantyType: warrantyType,
                startDate: warrantyStartDate,
                endDate: computedWarrantyEndDate,
                provider: provider.isEmpty ? nil : provider,
                contactInfo: providerContact.isEmpty ? nil : providerContact,
                appliance: appliance
            )
            warranty.pendingSync = true
            context.insert(warranty)
        }

        try context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return appliance
    }
}
