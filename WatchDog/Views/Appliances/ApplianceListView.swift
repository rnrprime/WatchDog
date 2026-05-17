import SwiftUI
import SwiftData

struct ApplianceListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Appliance.createdAt, order: .reverse) private var appliances: [Appliance]

    @State private var viewModel = ApplianceListViewModel()
    @State private var showAddSheet = false
    @State private var applianceToDelete: Appliance? = nil
    @State private var showDeleteConfirm = false

    private var filtered: [Appliance] {
        viewModel.filteredAppliances(appliances)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content
                    .navigationTitle("Appliances")
                    .navigationBarTitleDisplayMode(.large)
                    .searchable(
                        text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search appliances"
                    )
                    .toolbar { toolbarContent }
                    .navigationDestination(for: Appliance.self) { appliance in
                        ApplianceDetailView(appliance: appliance)
                    }
                    .confirmDelete(
                        isPresented: $showDeleteConfirm,
                        itemName: applianceToDelete?.name ?? "this appliance"
                    ) {
                        if let appliance = applianceToDelete {
                            viewModel.deleteAppliance(appliance, from: modelContext)
                        }
                        applianceToDelete = nil
                    }

                FloatingActionButton {
                    showAddSheet = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showAddSheet) {
                AddApplianceView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if appliances.isEmpty {
            EmptyStateView(
                icon: "tray",
                title: "No appliances yet",
                subtitle: "Tap + to add your first appliance and start tracking warranties."
            )
        } else {
            VStack(spacing: 0) {
                CategoryFilterChips(viewModel: viewModel, appliances: appliances)

                if filtered.isEmpty {
                    Spacer(minLength: 24)
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results",
                        subtitle: "Try a different search or change the filter."
                    )
                    Spacer()
                } else {
                    switch viewModel.viewMode {
                    case .list:
                        listMode
                    case .grid:
                        gridMode
                    }
                }
            }
        }
    }

    private var listMode: some View {
        List {
            ForEach(filtered) { appliance in
                NavigationLink(value: appliance) {
                    ApplianceRow(appliance: appliance)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color(.systemBackground))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        applianceToDelete = appliance
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        print("[Appliances] Edit \(appliance.name)")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Color.accentTeal)
                }
                .contextMenu {
                    Button {
                        print("[Appliances] Edit \(appliance.name)")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        print("[Appliances] Share \(appliance.name)")
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        applianceToDelete = appliance
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var gridMode: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 170), spacing: 16)],
                spacing: 16
            ) {
                ForEach(filtered) { appliance in
                    NavigationLink(value: appliance) {
                        ApplianceGridCard(appliance: appliance)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            print("[Appliances] Edit \(appliance.name)")
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            print("[Appliances] Share \(appliance.name)")
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive) {
                            applianceToDelete = appliance
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("View", selection: $viewModel.viewMode) {
                    Label("List", systemImage: "list.bullet")
                        .tag(ApplianceListViewModel.ViewMode.list)
                    Label("Grid", systemImage: "square.grid.2x2")
                        .tag(ApplianceListViewModel.ViewMode.grid)
                }
                Picker("Sort by", selection: $viewModel.sortOrder) {
                    ForEach(ApplianceListViewModel.SortOrder.allCases) { order in
                        Text(order.displayName).tag(order)
                    }
                }
            } label: {
                Image(systemName: viewModel.viewMode == .list
                    ? "list.bullet"
                    : "square.grid.2x2")
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
                    Label("Clear all data", systemImage: "trash.fill")
                }
            } label: {
                Image(systemName: "ladybug")
                    .foregroundStyle(Color.accentTeal)
            }
        }
        #endif
    }

    #if DEBUG
    private func seedTestData() {
        let now = Date.now
        let day: TimeInterval = 86400

        let fridge = Appliance(
            name: "Samsung Refrigerator",
            brand: "Samsung",
            model: "RT38K5562SL",
            serialNumber: "SR2024X1",
            category: .kitchen,
            purchaseDate: now.addingTimeInterval(-730 * day)
        )
        let washer = Appliance(
            name: "LG Washing Machine",
            brand: "LG",
            model: "F4WV510S0E",
            serialNumber: "LG2023Z9",
            category: .laundry,
            purchaseDate: now.addingTimeInterval(-365 * day)
        )
        let tv = Appliance(
            name: "Sony Bravia TV",
            brand: "Sony",
            model: "X90L",
            serialNumber: "SN54321",
            category: .electronics,
            purchaseDate: now.addingTimeInterval(-180 * day)
        )
        let vacuum = Appliance(
            name: "Dyson Vacuum",
            brand: "Dyson",
            model: "V15",
            serialNumber: "DY99887",
            category: .other,
            purchaseDate: now.addingTimeInterval(-90 * day)
        )
        let ac = Appliance(
            name: "Daikin AC",
            brand: "Daikin",
            model: "FTKM50",
            serialNumber: "DK11223",
            category: .hvac,
            purchaseDate: now.addingTimeInterval(-240 * day)
        )

        for appliance in [fridge, washer, tv, vacuum, ac] {
            modelContext.insert(appliance)
        }

        let warrantyFridge = Warranty(
            warrantyType: .manufacturer,
            startDate: now.addingTimeInterval(-730 * day),
            endDate: now.addingTimeInterval(90 * day),
            provider: "Samsung Care",
            appliance: fridge
        )
        let warrantyWasher = Warranty(
            warrantyType: .manufacturer,
            startDate: now.addingTimeInterval(-365 * day),
            endDate: now.addingTimeInterval(-30 * day),
            provider: "LG Direct",
            appliance: washer
        )
        let warrantyTV = Warranty(
            warrantyType: .manufacturer,
            startDate: now.addingTimeInterval(-180 * day),
            endDate: now.addingTimeInterval(540 * day),
            provider: "Sony",
            appliance: tv
        )
        let warrantyVacuum = Warranty(
            warrantyType: .manufacturer,
            startDate: now.addingTimeInterval(-90 * day),
            endDate: now.addingTimeInterval(21 * 30 * day),
            provider: "Dyson",
            appliance: vacuum
        )
        let warrantyAC = Warranty(
            warrantyType: .manufacturer,
            startDate: now.addingTimeInterval(-240 * day),
            endDate: now.addingTimeInterval(-5 * day),
            provider: "Daikin",
            appliance: ac
        )

        for warranty in [warrantyFridge, warrantyWasher, warrantyTV, warrantyVacuum, warrantyAC] {
            modelContext.insert(warranty)
        }

        try? modelContext.save()
    }

    private func clearAllData() {
        for appliance in appliances {
            modelContext.delete(appliance)
        }
        try? modelContext.save()
    }
    #endif
}
