import Foundation
import SwiftData
import Auth

enum UrgentItem: Identifiable {
    case appliance(Appliance, Warranty)
    case expiry(ExpiryItem)

    var id: String {
        switch self {
        case .appliance(_, let w): "w-\(w.id.uuidString)"
        case .expiry(let e): "e-\(e.id.uuidString)"
        }
    }

    var name: String {
        switch self {
        case .appliance(let a, _): a.name
        case .expiry(let e): e.name
        }
    }

    var endDate: Date {
        switch self {
        case .appliance(_, let w): w.endDate
        case .expiry(let e): e.expiryDate
        }
    }
}

enum RecentItem: Identifiable {
    case appliance(Appliance)
    case expiry(ExpiryItem)

    var id: String {
        switch self {
        case .appliance(let a): "a-\(a.id.uuidString)"
        case .expiry(let e): "e-\(e.id.uuidString)"
        }
    }

    var name: String {
        switch self {
        case .appliance(let a): a.name
        case .expiry(let e): e.name
        }
    }

    var createdAt: Date {
        switch self {
        case .appliance(let a): a.createdAt
        case .expiry(let e): e.createdAt
        }
    }
}

@Observable
@MainActor
final class HomeViewModel {
    var appliances: [Appliance] = []
    var expiryItems: [ExpiryItem] = []
    var warranties: [Warranty] = []
    var isLoading: Bool = true

    var userName: String {
        if UserDefaults.standard.bool(forKey: "isGuestMode") { return "there" }
        let metadata = SupabaseService.shared.currentUser?.userMetadata
        if let value = metadata?["full_name"],
           case .string(let name) = value,
           !name.isEmpty {
            return name
        }
        return "there"
    }

    var timeAwareGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return switch hour {
        case ..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Hello"
        }
    }

    var applianceCount: Int { appliances.count }

    var activeWarrantyCount: Int {
        warranties.filter { $0.endDate > .now }.count
    }

    var expiringItemsCount: Int {
        let expiringExpiries = expiryItems.filter { daysUntil($0.expiryDate) <= 30 }.count
        let expiringWarranties = warranties.filter {
            $0.endDate > .now && daysUntil($0.endDate) <= 30
        }.count
        return expiringExpiries + expiringWarranties
    }

    var urgentItems: [UrgentItem] {
        let warrantyUrgent: [UrgentItem] = warranties
            .filter { $0.endDate > .now && daysUntil($0.endDate) <= 7 }
            .compactMap { warranty in
                guard let appliance = warranty.appliance else { return nil }
                return .appliance(appliance, warranty)
            }
        let expiryUrgent: [UrgentItem] = expiryItems
            .filter { daysUntil($0.expiryDate) <= 7 }
            .map { .expiry($0) }
        return (warrantyUrgent + expiryUrgent).sorted { $0.endDate < $1.endDate }
    }

    var thisMonthItems: [UrgentItem] {
        let warrantyUpcoming: [UrgentItem] = warranties
            .filter {
                let d = daysUntil($0.endDate)
                return $0.endDate > .now && d > 7 && d <= 30
            }
            .compactMap { warranty in
                guard let appliance = warranty.appliance else { return nil }
                return .appliance(appliance, warranty)
            }
        let expiryUpcoming: [UrgentItem] = expiryItems
            .filter {
                let d = daysUntil($0.expiryDate)
                return d > 7 && d <= 30
            }
            .map { .expiry($0) }
        return (warrantyUpcoming + expiryUpcoming).sorted { $0.endDate < $1.endDate }
    }

    var recentItems: [RecentItem] {
        let mapped: [RecentItem] =
            appliances.map { .appliance($0) } + expiryItems.map { .expiry($0) }
        return Array(mapped.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }

    var hasNoData: Bool {
        appliances.isEmpty && expiryItems.isEmpty
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    func loadData() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        isLoading = false
    }
}
