import Foundation
import SwiftData

/// Inserts a curated set of beautiful demo data — used to take App Store
/// screenshots. Triggered from Settings → Version row (5 taps) → Debug.
/// Idempotent-ish: clears existing data first so screenshots look consistent.
enum DemoDataLoader {
    @MainActor
    static func load(into context: ModelContext) {
        clearAll(in: context)

        let now = Date.now
        let day: TimeInterval = 86400

        // MARK: Appliances

        let fridge = Appliance(
            name: "Samsung Smart Fridge",
            brand: "Samsung",
            model: "RF28R7351SR",
            serialNumber: "SN-2024-7821X",
            category: .kitchen,
            purchaseDate: now.addingTimeInterval(-420 * day),
            purchasePrice: 2199,
            store: "Best Buy"
        )
        let washer = Appliance(
            name: "LG Front-Load Washer",
            brand: "LG",
            model: "WM4000HWA",
            serialNumber: "LG-WD-552103",
            category: .laundry,
            purchaseDate: now.addingTimeInterval(-280 * day),
            purchasePrice: 1099,
            store: "Home Depot"
        )
        let tv = Appliance(
            name: "Sony Bravia 65\" OLED",
            brand: "Sony",
            model: "XR-65A95L",
            serialNumber: "SONY-A95L-22441",
            category: .electronics,
            purchaseDate: now.addingTimeInterval(-180 * day),
            purchasePrice: 2899,
            store: "Sony Store"
        )
        let ac = Appliance(
            name: "Daikin Mini-Split AC",
            brand: "Daikin",
            model: "FTXS24LVJU",
            serialNumber: "DKN-MS-09122",
            category: .hvac,
            purchaseDate: now.addingTimeInterval(-95 * day),
            purchasePrice: 1850,
            store: "Local HVAC Pro"
        )
        let mixer = Appliance(
            name: "KitchenAid Stand Mixer",
            brand: "KitchenAid",
            model: "Artisan KSM150PS",
            serialNumber: "KA-AR-991034",
            category: .kitchen,
            purchaseDate: now.addingTimeInterval(-60 * day),
            purchasePrice: 449,
            store: "Williams Sonoma"
        )
        let vacuum = Appliance(
            name: "Dyson V15 Detect",
            brand: "Dyson",
            model: "V15",
            serialNumber: "DY-V15-22099",
            category: .other,
            purchaseDate: now.addingTimeInterval(-35 * day),
            purchasePrice: 749,
            store: "Dyson Direct"
        )
        let dishwasher = Appliance(
            name: "Bosch 800 Series Dishwasher",
            brand: "Bosch",
            model: "SHPM78Z55N",
            serialNumber: "BSH-78Z-77231",
            category: .kitchen,
            purchaseDate: now.addingTimeInterval(-540 * day),
            purchasePrice: 1349,
            store: "Lowe's"
        )
        let grill = Appliance(
            name: "Weber Genesis II Grill",
            brand: "Weber",
            model: "Genesis II E-310",
            serialNumber: "WBR-GII-31002",
            category: .outdoor,
            purchaseDate: now.addingTimeInterval(-650 * day),
            purchasePrice: 899,
            store: "Ace Hardware"
        )

        let appliances = [fridge, washer, tv, ac, mixer, vacuum, dishwasher, grill]
        for appliance in appliances {
            context.insert(appliance)
        }

        // MARK: Warranties (mixed urgency)

        let warranties: [Warranty] = [
            // Healthy
            Warranty(
                warrantyType: .both,
                startDate: now.addingTimeInterval(-420 * day),
                endDate: now.addingTimeInterval(310 * day),
                provider: "Samsung Care+",
                appliance: fridge
            ),
            // Expiring soon (28 days)
            Warranty(
                warrantyType: .manufacturer,
                startDate: now.addingTimeInterval(-280 * day),
                endDate: now.addingTimeInterval(28 * day),
                provider: "LG Direct",
                appliance: washer
            ),
            // Long way off
            Warranty(
                warrantyType: .extended,
                startDate: now.addingTimeInterval(-180 * day),
                endDate: now.addingTimeInterval(1280 * day),
                provider: "Sony Protect Plus",
                appliance: tv
            ),
            // Healthy
            Warranty(
                warrantyType: .manufacturer,
                startDate: now.addingTimeInterval(-95 * day),
                endDate: now.addingTimeInterval(540 * day),
                provider: "Daikin",
                appliance: ac
            ),
            // Just expired
            Warranty(
                warrantyType: .manufacturer,
                startDate: now.addingTimeInterval(-410 * day),
                endDate: now.addingTimeInterval(-7 * day),
                provider: "KitchenAid",
                appliance: mixer
            ),
            // Healthy
            Warranty(
                warrantyType: .both,
                startDate: now.addingTimeInterval(-35 * day),
                endDate: now.addingTimeInterval(695 * day),
                provider: "Dyson",
                appliance: vacuum
            ),
            // Soon-ish (75 days)
            Warranty(
                warrantyType: .manufacturer,
                startDate: now.addingTimeInterval(-540 * day),
                endDate: now.addingTimeInterval(75 * day),
                provider: "Bosch",
                appliance: dishwasher
            ),
            // Expired long ago
            Warranty(
                warrantyType: .manufacturer,
                startDate: now.addingTimeInterval(-650 * day),
                endDate: now.addingTimeInterval(-285 * day),
                provider: "Weber",
                appliance: grill
            )
        ]
        for w in warranties { context.insert(w) }

        // MARK: Expiry items (mixed urgency)

        let expiryItems: [ExpiryItem] = [
            ExpiryItem(
                name: "US Passport",
                category: .document,
                expiryDate: now.addingTimeInterval(45 * day),
                notes: "Renew well before international travel — processing can take 8 weeks."
            ),
            ExpiryItem(
                name: "Atorvastatin 20mg",
                category: .medication,
                expiryDate: now.addingTimeInterval(-3 * day),
                quantity: 30,
                unit: "tablets"
            ),
            ExpiryItem(
                name: "Olive oil — first cold press",
                category: .food,
                expiryDate: now.addingTimeInterval(180 * day),
                quantity: 1,
                unit: "bottle"
            ),
            ExpiryItem(
                name: "Netflix Premium",
                category: .subscription,
                expiryDate: now.addingTimeInterval(12 * day),
                isRecurring: true,
                recurrenceIntervalDays: 30
            ),
            ExpiryItem(
                name: "Auto Insurance — State Farm",
                category: .insurance,
                expiryDate: now.addingTimeInterval(96 * day),
                isRecurring: true,
                recurrenceIntervalDays: 365
            ),
            ExpiryItem(
                name: "Vehicle Registration — CA",
                category: .vehicle,
                expiryDate: now.addingTimeInterval(7 * day),
                isRecurring: true,
                recurrenceIntervalDays: 365
            )
        ]
        for item in expiryItems { context.insert(item) }

        try? context.save()
    }

    @MainActor
    static func clearAll(in context: ModelContext) {
        let appliances = (try? context.fetch(FetchDescriptor<Appliance>())) ?? []
        for appliance in appliances { context.delete(appliance) }

        let warranties = (try? context.fetch(FetchDescriptor<Warranty>())) ?? []
        for w in warranties { context.delete(w) }

        let items = (try? context.fetch(FetchDescriptor<ExpiryItem>())) ?? []
        for item in items { context.delete(item) }

        try? context.save()
    }
}
