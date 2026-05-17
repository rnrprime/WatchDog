import SwiftUI
import SwiftData

enum ExpirySection: String, CaseIterable, Identifiable {
    case overdue, thisWeek, thisMonth, later
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .overdue: "Overdue"
        case .thisWeek: "This week"
        case .thisMonth: "This month"
        case .later: "Later"
        }
    }

    var headerColor: Color {
        switch self {
        case .overdue: Color.statusExpired
        case .thisWeek: .orange
        case .thisMonth: Color(red: 1.0, green: 0.75, blue: 0.0)
        case .later: .gray
        }
    }
}

@Observable
@MainActor
final class ExpiryListViewModel {
    enum SortOrder: String, CaseIterable, Identifiable {
        case urgency, name, dateAdded
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .urgency: "Urgency"
            case .name: "Name"
            case .dateAdded: "Recently added"
            }
        }
    }

    var searchText: String = ""
    var selectedCategory: ExpiryCategory? = nil
    var sortOrder: SortOrder = .urgency

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    func filteredItems(_ all: [ExpiryItem]) -> [ExpiryItem] {
        var result = all
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needle = trimmed.lowercased()
            result = result.filter { item in
                if item.name.lowercased().contains(needle) { return true }
                if let notes = item.notes?.lowercased(), notes.contains(needle) { return true }
                return false
            }
        }
        return result
    }

    func groupedItems(
        _ all: [ExpiryItem]
    ) -> [(section: ExpirySection, items: [ExpiryItem])] {
        let filtered = filteredItems(all)
        var buckets: [ExpirySection: [ExpiryItem]] = [:]
        for item in filtered {
            let section: ExpirySection
            if item.expiryDate < .now {
                section = .overdue
            } else {
                let days = daysUntil(item.expiryDate)
                if days <= 7 {
                    section = .thisWeek
                } else if days <= 30 {
                    section = .thisMonth
                } else {
                    section = .later
                }
            }
            buckets[section, default: []].append(item)
        }
        return ExpirySection.allCases.compactMap { section in
            guard let items = buckets[section], !items.isEmpty else { return nil }
            let sorted = sortItems(items)
            return (section, sorted)
        }
    }

    private func sortItems(_ items: [ExpiryItem]) -> [ExpiryItem] {
        switch sortOrder {
        case .urgency:
            return items.sorted { $0.expiryDate < $1.expiryDate }
        case .name:
            return items.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .dateAdded:
            return items.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func categoryCount(for category: ExpiryCategory?, in all: [ExpiryItem]) -> Int {
        guard let category else { return all.count }
        return all.filter { $0.category == category }.count
    }

    func urgentCountForCategory(category: ExpiryCategory?, in all: [ExpiryItem]) -> Int {
        let scoped: [ExpiryItem]
        if let category {
            scoped = all.filter { $0.category == category }
        } else {
            scoped = all
        }
        return scoped.filter { item in
            if item.expiryDate < .now { return true }
            let days = daysUntil(item.expiryDate)
            return days <= 7
        }.count
    }
}
