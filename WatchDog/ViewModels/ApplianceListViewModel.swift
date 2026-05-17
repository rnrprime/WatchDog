import Foundation
import SwiftData

@Observable
@MainActor
final class ApplianceListViewModel {
    enum SortOrder: String, CaseIterable, Identifiable {
        case name, dateAdded, warrantyStatus
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .name: "Name"
            case .dateAdded: "Recently added"
            case .warrantyStatus: "Warranty status"
            }
        }
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case list, grid
        var id: String { rawValue }
    }

    var searchText: String = ""
    var selectedCategory: ApplianceCategory? = nil
    var sortOrder: SortOrder = .dateAdded
    var viewMode: ViewMode = .list

    func filteredAppliances(_ all: [Appliance]) -> [Appliance] {
        var result = all

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needle = trimmed.lowercased()
            result = result.filter { a in
                if a.name.lowercased().contains(needle) { return true }
                if let brand = a.brand?.lowercased(), brand.contains(needle) { return true }
                if let model = a.model?.lowercased(), model.contains(needle) { return true }
                if let serial = a.serialNumber?.lowercased(), serial.contains(needle) {
                    return true
                }
                return false
            }
        }

        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            result.sort { $0.createdAt > $1.createdAt }
        case .warrantyStatus:
            result.sort {
                let lhs = warrantyStatusRank(for: $0)
                let rhs = warrantyStatusRank(for: $1)
                if lhs != rhs { return lhs < rhs }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        return result
    }

    private func warrantyStatusRank(for appliance: Appliance) -> Int {
        guard let earliest = appliance.warranties.map(\.endDate).min() else { return 3 }
        let days = Calendar.current.dateComponents([.day], from: .now, to: earliest).day ?? 0
        if days < 0 { return 0 }
        if days <= 30 { return 1 }
        return 2
    }

    func categoryCount(for category: ApplianceCategory?, in all: [Appliance]) -> Int {
        guard let category else { return all.count }
        return all.filter { $0.category == category }.count
    }

    func deleteAppliance(_ appliance: Appliance, from context: ModelContext) {
        let supabaseId = appliance.supabaseId
        let warrantyIds = appliance.warranties.map(\.id)
        let warrantySupabaseIds = appliance.warranties.compactMap(\.supabaseId)

        context.delete(appliance)
        try? context.save()

        NotificationService.shared.cancelReminders(entityId: appliance.id)
        for wId in warrantyIds {
            NotificationService.shared.cancelReminders(entityId: wId)
        }

        if let id = supabaseId {
            Task {
                await SyncService.shared.deleteFromCloud(entityType: "appliances", supabaseId: id)
            }
        }
        for wId in warrantySupabaseIds {
            Task {
                await SyncService.shared.deleteFromCloud(entityType: "warranties", supabaseId: wId)
            }
        }
    }
}
