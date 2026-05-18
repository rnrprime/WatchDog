import SwiftUI
import SwiftData

struct HomeView: View {
    /// Called when Home wants the parent tab view to switch tabs.
    /// 1 = Appliances, 2 = Expiry, 3 = Settings.
    var onSwitchTab: ((Int) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Appliance.createdAt, order: .reverse) private var appliances: [Appliance]
    @Query(sort: \ExpiryItem.createdAt, order: .reverse) private var expiryItems: [ExpiryItem]
    @Query(sort: \Warranty.endDate) private var warranties: [Warranty]

    @State private var viewModel = HomeViewModel()
    @State private var showAddAppliance = false
    @State private var showAddExpiry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    greetingHeader

                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.hasNoData {
                        emptyState
                    } else {
                        if !viewModel.urgentItems.isEmpty {
                            UrgentBannerView(count: viewModel.urgentItems.count) {
                                onSwitchTab?(2)
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
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarButtons }
            .navigationDestination(for: Appliance.self) { appliance in
                ApplianceDetailView(appliance: appliance)
            }
            .navigationDestination(for: ExpiryItem.self) { item in
                ExpiryDetailView(item: item)
            }
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .notifications:
                    NotificationSettingsView()
                }
            }
            .sheet(isPresented: $showAddAppliance) { AddApplianceView() }
            .sheet(isPresented: $showAddExpiry) { AddExpiryView() }
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 4) {
                NavigationLink(value: HomeDestination.notifications) {
                    Image(systemName: "bell.fill")
                        .overlay(alignment: .topTrailing) {
                            if !viewModel.urgentItems.isEmpty {
                                Circle()
                                    .fill(Color.statusExpired)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Notification settings")

                Button {
                    HapticsService.selection()
                    onSwitchTab?(3)
                } label: {
                    Image(systemName: "person.crop.circle")
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Open profile")
            }
            .foregroundStyle(Color.accentTeal)
        }
    }

    // MARK: - Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(viewModel.timeAwareGreeting),")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
            Text("\(viewModel.userName) 👋")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(.label))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats (2 cards, full width)

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatChipView(
                label: "Appliances",
                count: viewModel.applianceCount,
                systemImage: "refrigerator.fill",
                subtitle: warrantySubtitle
            ) {
                onSwitchTab?(1)
            }
            StatChipView(
                label: "Expiring",
                count: viewModel.expiringItemsCount,
                systemImage: "clock.fill",
                subtitle: viewModel.expiringItemsCount == 0
                    ? "Nothing soon"
                    : "in the next 30 days",
                tint: viewModel.expiringItemsCount > 0 ? .orange : Color.accentTeal
            ) {
                onSwitchTab?(2)
            }
        }
    }

    private var warrantySubtitle: String {
        let count = viewModel.activeWarrantyCount
        if viewModel.applianceCount == 0 { return "Start tracking" }
        switch count {
        case 0: return "No active warranty"
        case 1: return "1 active warranty"
        default: return "\(count) active warranties"
        }
    }

    // MARK: - This month

    private var thisMonthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Expiring this month", trailing: "View all") {
                onSwitchTab?(2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.thisMonthItems) { item in
                        miniCardLink(for: item)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - Recently added

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Recently added")
            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentItems.enumerated()), id: \.element.id) { idx, item in
                    recentRowLink(
                        for: item,
                        showsDivider: idx != viewModel.recentItems.count - 1
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Section title helper

    @ViewBuilder
    private func sectionTitle(
        _ title: String,
        trailing: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.label))
            Spacer()
            if let trailing, let action {
                Button(action: action) {
                    Text(trailing)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.accentTeal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Row navigation helpers

    @ViewBuilder
    private func miniCardLink(for item: UrgentItem) -> some View {
        switch item {
        case .appliance(let appliance, _):
            NavigationLink(value: appliance) {
                ExpiryMiniCard(item: item)
            }
            .buttonStyle(.plain)
        case .expiry(let expiry):
            NavigationLink(value: expiry) {
                ExpiryMiniCard(item: item)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func recentRowLink(for item: RecentItem, showsDivider: Bool) -> some View {
        switch item {
        case .appliance(let appliance):
            NavigationLink(value: appliance) {
                RecentRowView(item: item, showsDivider: showsDivider)
            }
            .buttonStyle(.plain)
        case .expiry(let expiry):
            NavigationLink(value: expiry) {
                RecentRowView(item: item, showsDivider: showsDivider)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Loading + Empty

    private var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.top, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            EmptyStateView(
                icon: "tray.fill",
                title: "Welcome to Watchdog",
                subtitle: "Add your first appliance or expiry item to start tracking."
            )
            .frame(minHeight: 320)
            HStack(spacing: 12) {
                PrimaryButton(title: "Add appliance") {
                    HapticsService.selection()
                    showAddAppliance = true
                }
                SecondaryButton(title: "Track expiry") {
                    HapticsService.selection()
                    showAddExpiry = true
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Navigation targets

private enum HomeDestination: Hashable {
    case notifications
}

// MARK: - Previews

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
    ctx.insert(Warranty(
        warrantyType: .manufacturer,
        startDate: now.addingTimeInterval(-300 * day),
        endDate: now.addingTimeInterval(5 * day),
        appliance: fridge
    ))
    ctx.insert(Warranty(
        warrantyType: .extended,
        startDate: now.addingTimeInterval(-100 * day),
        endDate: now.addingTimeInterval(20 * day),
        appliance: washer
    ))
    ctx.insert(Warranty(
        warrantyType: .manufacturer,
        startDate: now.addingTimeInterval(-50 * day),
        endDate: now.addingTimeInterval(400 * day),
        appliance: tv
    ))

    ctx.insert(ExpiryItem(
        name: "Passport",
        category: .document,
        expiryDate: now.addingTimeInterval(3 * day)
    ))
    ctx.insert(ExpiryItem(
        name: "Vitamin D",
        category: .medication,
        expiryDate: now.addingTimeInterval(18 * day)
    ))
    ctx.insert(ExpiryItem(
        name: "Netflix",
        category: .subscription,
        expiryDate: now.addingTimeInterval(45 * day)
    ))

    return container
}
