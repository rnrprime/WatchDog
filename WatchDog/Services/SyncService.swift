import Foundation
import SwiftData
import UIKit
import Supabase

struct AppliancePayload: Codable {
    let id: String
    let user_id: String
    let name: String
    let brand: String?
    let model: String?
    let serial_number: String?
    let category: String
    let purchase_date: String?
    let purchase_price: Double?
    let store: String?
    let notes: String?
    let photo_url: String?
}

struct WarrantyPayload: Codable {
    let id: String
    let user_id: String
    let appliance_id: String
    let warranty_type: String
    let start_date: String
    let end_date: String
    let provider: String?
    let contact_info: String?
    let notes: String?
}

struct ExpiryItemPayload: Codable {
    let id: String
    let user_id: String
    let name: String
    let category: String
    let expiry_date: String
    let quantity: Double?
    let unit: String?
    let notes: String?
    let is_recurring: Bool
    let recurrence_interval_days: Int?
    let photo_url: String?
}

@Observable
@MainActor
final class SyncService {
    static let shared = SyncService()

    var isSyncing: Bool = false
    var syncErrorMessage: String? = nil

    @ObservationIgnored
    private var lastSyncTimestamp: TimeInterval {
        get { UserDefaults.standard.double(forKey: "lastSyncDate") }
        set { UserDefaults.standard.set(newValue, forKey: "lastSyncDate") }
    }

    var lastSyncDate: Date? {
        let t = lastSyncTimestamp
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    var modelContainer: ModelContainer?

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.syncPendingItems()
            }
        }
    }

    func setup(container: ModelContainer) {
        self.modelContainer = container
    }

    private var isGuestMode: Bool {
        UserDefaults.standard.bool(forKey: "isGuestMode")
    }

    private var currentUserId: String? {
        SupabaseService.shared.currentUser?.id.uuidString
    }

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private func dateString(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.isoDateFormatter.string(from: date)
    }

    func syncAppliance(_ appliance: Appliance) async {
        guard !isGuestMode else {
            appliance.pendingSync = false
            return
        }
        guard let userId = currentUserId else { return }

        if appliance.supabaseId == nil {
            appliance.supabaseId = appliance.id
        }
        guard let supabaseId = appliance.supabaseId else { return }

        let purchasePriceDouble: Double? = appliance.purchasePrice.map {
            NSDecimalNumber(decimal: $0).doubleValue
        }

        let payload = AppliancePayload(
            id: supabaseId.uuidString,
            user_id: userId,
            name: appliance.name,
            brand: appliance.brand,
            model: appliance.model,
            serial_number: appliance.serialNumber,
            category: appliance.category.rawValue,
            purchase_date: dateString(appliance.purchaseDate),
            purchase_price: purchasePriceDouble,
            store: appliance.store,
            notes: appliance.notes,
            photo_url: appliance.photoURL
        )

        do {
            try await client.from("appliances").upsert(payload).execute()
            appliance.pendingSync = false
            try? appliance.modelContext?.save()
        } catch {
            #if DEBUG
            print("[Sync] Appliance sync failed: \(error)")
            #endif
            syncErrorMessage = "Sync failed — will retry"
        }
    }

    func syncWarranty(_ warranty: Warranty) async {
        guard !isGuestMode else {
            warranty.pendingSync = false
            return
        }
        guard let userId = currentUserId else { return }
        guard let appliance = warranty.appliance else { return }

        if warranty.supabaseId == nil {
            warranty.supabaseId = warranty.id
        }
        if appliance.supabaseId == nil {
            appliance.supabaseId = appliance.id
        }
        guard let warrantyId = warranty.supabaseId,
              let applianceId = appliance.supabaseId
        else { return }

        guard let startStr = dateString(warranty.startDate),
              let endStr = dateString(warranty.endDate)
        else { return }

        let payload = WarrantyPayload(
            id: warrantyId.uuidString,
            user_id: userId,
            appliance_id: applianceId.uuidString,
            warranty_type: warranty.warrantyType.rawValue,
            start_date: startStr,
            end_date: endStr,
            provider: warranty.provider,
            contact_info: warranty.contactInfo,
            notes: warranty.notes
        )

        do {
            try await client.from("warranties").upsert(payload).execute()
            warranty.pendingSync = false
            try? warranty.modelContext?.save()
        } catch {
            #if DEBUG
            print("[Sync] Warranty sync failed: \(error)")
            #endif
            syncErrorMessage = "Sync failed — will retry"
        }
    }

    func syncExpiryItem(_ item: ExpiryItem) async {
        guard !isGuestMode else {
            item.pendingSync = false
            return
        }
        guard let userId = currentUserId else { return }

        if item.supabaseId == nil {
            item.supabaseId = item.id
        }
        guard let supabaseId = item.supabaseId else { return }
        guard let expiryStr = dateString(item.expiryDate) else { return }

        let qty: Double? = item.quantity.map {
            NSDecimalNumber(decimal: $0).doubleValue
        }

        let payload = ExpiryItemPayload(
            id: supabaseId.uuidString,
            user_id: userId,
            name: item.name,
            category: item.category.rawValue,
            expiry_date: expiryStr,
            quantity: qty,
            unit: item.unit,
            notes: item.notes,
            is_recurring: item.isRecurring,
            recurrence_interval_days: item.recurrenceIntervalDays,
            photo_url: item.photoURL
        )

        do {
            try await client.from("expiry_items").upsert(payload).execute()
            item.pendingSync = false
            try? item.modelContext?.save()
        } catch {
            #if DEBUG
            print("[Sync] ExpiryItem sync failed: \(error)")
            #endif
            syncErrorMessage = "Sync failed — will retry"
        }
    }

    func deleteFromCloud(entityType: String, supabaseId: UUID) async {
        guard !isGuestMode else { return }
        guard currentUserId != nil else { return }

        do {
            try await client.from(entityType)
                .delete()
                .eq("id", value: supabaseId.uuidString)
                .execute()
        } catch {
            #if DEBUG
            print("[Sync] Delete failed for \(entityType): \(error)")
            #endif
        }
    }

    func syncPendingItems() async {
        guard !isSyncing else { return }
        guard !isGuestMode else { return }
        guard currentUserId != nil else { return }
        guard let container = modelContainer else { return }

        isSyncing = true
        defer { isSyncing = false }

        let context = ModelContext(container)

        let pendingAppliances = (try? context.fetch(
            FetchDescriptor<Appliance>(predicate: #Predicate { $0.pendingSync == true })
        )) ?? []
        for appliance in pendingAppliances {
            await syncAppliance(appliance)
        }

        let pendingWarranties = (try? context.fetch(
            FetchDescriptor<Warranty>(predicate: #Predicate { $0.pendingSync == true })
        )) ?? []
        for warranty in pendingWarranties {
            await syncWarranty(warranty)
        }

        let pendingExpiryItems = (try? context.fetch(
            FetchDescriptor<ExpiryItem>(predicate: #Predicate { $0.pendingSync == true })
        )) ?? []
        for item in pendingExpiryItems {
            await syncExpiryItem(item)
        }

        lastSyncTimestamp = Date.now.timeIntervalSince1970
    }

    func pullFromCloud() async {
        guard !isGuestMode else { return }
        guard currentUserId != nil else { return }
        guard let container = modelContainer else { return }

        let context = ModelContext(container)

        do {
            let response: [AppliancePayload] = try await client
                .from("appliances")
                .select()
                .execute()
                .value

            for row in response {
                guard let supabaseId = UUID(uuidString: row.id) else { continue }
                let existing = try? context.fetch(
                    FetchDescriptor<Appliance>(predicate: #Predicate {
                        $0.supabaseId == supabaseId
                    })
                )
                if existing?.isEmpty == false { continue }

                let category = ApplianceCategory(rawValue: row.category) ?? .other
                let purchaseDate = row.purchase_date.flatMap {
                    Self.isoDateFormatter.date(from: $0)
                }
                let price = row.purchase_price.map { Decimal($0) }

                let appliance = Appliance(
                    name: row.name,
                    brand: row.brand,
                    model: row.model,
                    serialNumber: row.serial_number,
                    category: category,
                    purchaseDate: purchaseDate,
                    purchasePrice: price,
                    store: row.store,
                    notes: row.notes,
                    photoURL: row.photo_url
                )
                appliance.supabaseId = supabaseId
                appliance.pendingSync = false
                context.insert(appliance)
            }

            try? context.save()
            lastSyncTimestamp = Date.now.timeIntervalSince1970
        } catch {
            #if DEBUG
            print("[Sync] Pull failed: \(error)")
            #endif
        }
    }
}
