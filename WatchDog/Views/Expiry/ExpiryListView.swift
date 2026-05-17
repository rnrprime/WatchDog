import SwiftUI
import SwiftData

struct ExpiryListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ExpiryItem.expiryDate) private var allItems: [ExpiryItem]

    @State private var viewModel = ExpiryListViewModel()
    @State private var showAddSheet = false
    @State private var itemToRenew: ExpiryItem? = nil
    @State private var itemToDelete: ExpiryItem? = nil
    @State private var showDeleteConfirm = false
    @State private var showRenewedToast = false

    private var groupedItems: [(section: ExpirySection, items: [ExpiryItem])] {
        viewModel.groupedItems(allItems)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content
                    .navigationTitle("Expiry")
                    .navigationBarTitleDisplayMode(.large)
                    .searchable(
                        text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search expiry items"
                    )
                    .toolbar { toolbarContent }
                    .navigationDestination(for: ExpiryItem.self) { item in
                        ExpiryDetailView(item: item)
                    }
                    .confirmDelete(
                        isPresented: $showDeleteConfirm,
                        itemName: itemToDelete?.name ?? "this item"
                    ) {
                        if let item = itemToDelete {
                            let supabaseId = item.supabaseId
                            let entityId = item.id
                            modelContext.delete(item)
                            try? modelContext.save()
                            NotificationService.shared.cancelReminders(entityId: entityId)
                            if let id = supabaseId {
                                Task {
                                    await SyncService.shared.deleteFromCloud(
                                        entityType: "expiry_items", supabaseId: id
                                    )
                                }
                            }
                        }
                        itemToDelete = nil
                    }

                if !allItems.isEmpty {
                    FloatingActionButton {
                        showAddSheet = true
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
                }
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showAddSheet) {
                AddExpiryView()
            }
            .sheet(item: $itemToRenew) { item in
                RenewExpiryView(item: item) { _ in
                    showToast()
                }
            }
            .overlay(alignment: .top) {
                if showRenewedToast {
                    Text("Renewed! Reminders updated.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if allItems.isEmpty {
            EmptyStateView(
                icon: "clock.badge.checkmark",
                title: "Nothing expiring",
                subtitle: "Track passports, medications, subscriptions, and anything else with an expiry date.",
                actionLabel: "Track first item"
            ) {
                showAddSheet = true
            }
        } else {
            List {
                Section {
                    ExpiryCategoryFilterChips(viewModel: viewModel, items: allItems)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if groupedItems.isEmpty {
                    Section {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No results",
                            subtitle: "Try a different search or filter."
                        )
                        .frame(minHeight: 280)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(groupedItems, id: \.section.id) { group in
                        Section {
                            ForEach(group.items) { item in
                                rowEntry(for: item)
                            }
                        } header: {
                            ExpirySectionHeader(section: group.section, count: group.items.count)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .animation(.easeInOut(duration: 0.3), value: allItems.map(\.expiryDate))
        }
    }

    @ViewBuilder
    private func rowEntry(for item: ExpiryItem) -> some View {
        NavigationLink(value: item) {
            ExpiryRow(item: item, onToggleReminder: {
                print("[Expiry] Toggle reminder for \(item.name)")
            })
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color(.systemBackground))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                itemToRenew = item
            } label: {
                Label("Renewed", systemImage: "arrow.clockwise")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                itemToDelete = item
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            NavigationLink(value: item) {
                Label("View", systemImage: "eye")
            }
            Button {
                itemToRenew = item
            } label: {
                Label("Renew", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive) {
                itemToDelete = item
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort by", selection: $viewModel.sortOrder) {
                    ForEach(ExpiryListViewModel.SortOrder.allCases) { order in
                        Text(order.displayName).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundStyle(Color.accentTeal)
            }
        }

        #if DEBUG
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    seedTestData()
                } label: {
                    Label("Seed test data", systemImage: "ladybug.fill")
                }
                Button(role: .destructive) {
                    clearAllData()
                } label: {
                    Label("Clear all expiry data", systemImage: "trash.fill")
                }
            } label: {
                Image(systemName: "ladybug")
                    .foregroundStyle(Color.accentTeal)
            }
        }
        #endif
    }

    private func showToast() {
        withAnimation(.spring(duration: 0.3)) { showRenewedToast = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.spring(duration: 0.3)) { showRenewedToast = false }
        }
    }

    #if DEBUG
    private func seedTestData() {
        let now = Date.now
        let day: TimeInterval = 86400

        let passport = ExpiryItem(
            name: "UK Passport",
            category: .document,
            expiryDate: now.addingTimeInterval(45 * day),
            isRecurring: true,
            recurrenceIntervalDays: 120 * 30
        )
        let vitamin = ExpiryItem(
            name: "Vitamin D Tablets",
            category: .medication,
            expiryDate: now.addingTimeInterval(-5 * day)
        )
        let oil = ExpiryItem(
            name: "Olive Oil",
            category: .food,
            expiryDate: now.addingTimeInterval(3 * day)
        )
        let netflix = ExpiryItem(
            name: "Netflix Annual",
            category: .subscription,
            expiryDate: now.addingTimeInterval(18 * day),
            isRecurring: true,
            recurrenceIntervalDays: 12 * 30
        )
        let insurance = ExpiryItem(
            name: "Home Insurance",
            category: .insurance,
            expiryDate: now.addingTimeInterval(90 * day),
            isRecurring: true,
            recurrenceIntervalDays: 12 * 30
        )
        let registration = ExpiryItem(
            name: "Car Registration",
            category: .vehicle,
            expiryDate: now.addingTimeInterval(-2 * day),
            isRecurring: true,
            recurrenceIntervalDays: 12 * 30
        )

        for item in [passport, vitamin, oil, netflix, insurance, registration] {
            item.pendingSync = true
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

    private func clearAllData() {
        for item in allItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    #endif
}
