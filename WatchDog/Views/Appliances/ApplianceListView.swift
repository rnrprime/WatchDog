import SwiftUI
import SwiftData

struct ApplianceListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Appliance.createdAt, order: .reverse) private var appliances: [Appliance]

    @State private var viewModel = ApplianceListViewModel()
    @State private var entitlements = EntitlementManager.shared
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
                    if entitlements.checkApplianceLimit(currentCount: appliances.count) {
                        showAddSheet = true
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showAddSheet) {
                AddApplianceView()
            }
            .sheet(item: paywallBinding) { trigger in
                PaywallView(trigger: trigger) {
                    entitlements.clearTrigger()
                }
            }
        }
    }

    private var paywallBinding: Binding<PaywallTrigger?> {
        Binding(
            get: { entitlements.paywallTrigger },
            set: { entitlements.paywallTrigger = $0 }
        )
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
                        DebugLog("[Appliances] Edit \(appliance.name)")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Color.accentTeal)
                }
                .contextMenu {
                    Button {
                        DebugLog("[Appliances] Edit \(appliance.name)")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        DebugLog("[Appliances] Share \(appliance.name)")
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
                            DebugLog("[Appliances] Edit \(appliance.name)")
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            DebugLog("[Appliances] Share \(appliance.name)")
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

    }
}
