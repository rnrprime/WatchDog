import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Appliance.createdAt, order: .reverse) private var appliances: [Appliance]
    @Query(sort: \ExpiryItem.createdAt, order: .reverse) private var expiryItems: [ExpiryItem]
    @Query(sort: \Warranty.endDate) private var warranties: [Warranty]

    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.hasNoData {
                        emptyState
                    } else {
                        if !viewModel.urgentItems.isEmpty {
                            UrgentBannerView(count: viewModel.urgentItems.count) {
                                DebugLog("[Home] Tap urgent banner")
                            }
                        }

                        statsRow

                        if !viewModel.thisMonthItems.isEmpty {
                            thisMonthSection
                        }

                        if !viewModel.recentItems.isEmpty {
                            recentSection
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .navigationTitle("\(viewModel.timeAwareGreeting), \(viewModel.userName)!")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            DebugLog("[Home] Tap notifications")
                        } label: {
                            Image(systemName: "bell.fill")
                                .overlay(alignment: .topTrailing) {
                                    if !viewModel.urgentItems.isEmpty {
                                        Circle()
                                            .fill(Color.statusExpired)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 4, y: -4)
                                    }
                                }
                        }
                        Button {
                            DebugLog("[Home] Tap profile")
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    }
                    .foregroundStyle(Color.accentTeal)
                }
            }
            .task {
                syncIntoViewModel()
                await viewModel.loadData()
            }
            .onChange(of: appliances) { _, _ in syncIntoViewModel() }
            .onChange(of: expiryItems) { _, _ in syncIntoViewModel() }
            .onChange(of: warranties) { _, _ in syncIntoViewModel() }
        }
    }

    private func syncIntoViewModel() {
        viewModel.appliances = appliances
        viewModel.expiryItems = expiryItems
        viewModel.warranties = warranties
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatChipView(
                label: "Appliances",
                count: viewModel.applianceCount,
                systemImage: "refrigerator.fill"
            ) {
                DebugLog("[Home] Tap appliances stat")
            }
            StatChipView(
                label: "Warranties",
                count: viewModel.activeWarrantyCount,
                systemImage: "shield.fill"
            ) {
                DebugLog("[Home] Tap warranties stat")
            }
            StatChipView(
                label: "Expiring",
                count: viewModel.expiringItemsCount,
                systemImage: "clock.fill",
                tint: viewModel.expiringItemsCount > 0 ? .orange : Color.accentTeal
            ) {
                DebugLog("[Home] Tap expiring stat")
            }
        }
    }

    private var thisMonthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Expiring this month", action: {
                DebugLog("[Home] See all expiring this month")
            })
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.thisMonthItems) { item in
                        ExpiryMiniCard(item: item) {
                            DebugLog("[Home] Tap mini card \(item.id)")
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Recently added", action: {
                DebugLog("[Home] View all recents")
            }, actionLabel: "View all")
            VStack(spacing: 0) {
                ForEach(viewModel.recentItems) { item in
                    RecentRowView(item: item) {
                        DebugLog("[Home] Tap recent \(item.id)")
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.top, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            EmptyStateView(
                icon: "tray.fill",
                title: "Welcome to Watchdog",
                subtitle: "Add your first appliance or expiry item to start tracking."
            )
            .frame(minHeight: 360)
            HStack(spacing: 12) {
                PrimaryButton(title: "Add appliance") {
                    DebugLog("[Home] Empty: add appliance")
                }
                SecondaryButton(title: "Track expiry") {
                    DebugLog("[Home] Empty: track expiry")
                }
            }
            .padding(.top, 12)
        }
    }
}

#Preview("With data") {
    HomeView()
        .modelContainer(makeMockHomeContainer())
}

#Preview("Empty") {
    HomeView()
        .modelContainer(makeEmptyHomeContainer())
}

@MainActor
private func makeEmptyHomeContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(
        for: Appliance.self, Warranty.self, ExpiryItem.self,
            Document.self, Reminder.self, UserProfile.self,
        configurations: config
    )
}

@MainActor
private func makeMockHomeContainer() -> ModelContainer {
    let container = makeEmptyHomeContainer()
    let ctx = container.mainContext

    let fridge = Appliance(name: "Refrigerator", brand: "LG", category: .kitchen)
    let washer = Appliance(name: "Washing Machine", brand: "Bosch", category: .laundry)
    let tv = Appliance(name: "Living Room TV", brand: "Sony", category: .electronics)
    ctx.insert(fridge)
    ctx.insert(washer)
    ctx.insert(tv)

    let now = Date.now
    let day: TimeInterval = 86400
    let warrantyFridge = Warranty(
        warrantyType: .manufacturer,
        startDate: now.addingTimeInterval(-300 * day),
        endDate: now.addingTimeInterval(5 * day),
        appliance: fridge
    )
    let warrantyWasher = Warranty(
        warrantyType: .extended,
        startDate: now.addingTimeInterval(-100 * day),
        endDate: now.addingTimeInterval(20 * day),
        appliance: washer
    )
    let warrantyTV = Warranty(
        warrantyType: .manufacturer,
        startDate: now.addingTimeInterval(-50 * day),
        endDate: now.addingTimeInterval(400 * day),
        appliance: tv
    )
    ctx.insert(warrantyFridge)
    ctx.insert(warrantyWasher)
    ctx.insert(warrantyTV)

    let passport = ExpiryItem(
        name: "Passport",
        category: .document,
        expiryDate: now.addingTimeInterval(3 * day)
    )
    let meds = ExpiryItem(
        name: "Vitamin D",
        category: .medication,
        expiryDate: now.addingTimeInterval(18 * day)
    )
    let netflix = ExpiryItem(
        name: "Netflix",
        category: .subscription,
        expiryDate: now.addingTimeInterval(45 * day)
    )
    ctx.insert(passport)
    ctx.insert(meds)
    ctx.insert(netflix)

    return container
}
