import SwiftUI

struct ComponentsPreview: View {
    @State private var showDeleteDialog = false
    @State private var isLoadingPrimary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    group("Status badges") {
                        VStack(alignment: .leading, spacing: 8) {
                            StatusBadge(daysRemaining: nil)
                            StatusBadge(daysRemaining: -10)
                            StatusBadge(daysRemaining: 14)
                            StatusBadge(daysRemaining: 60)
                            StatusBadge(daysRemaining: 200)
                        }
                    }

                    group("Days countdown") {
                        VStack(alignment: .leading, spacing: 8) {
                            DaysCountdownView(endDate: .now.addingTimeInterval(-3 * 86400), style: .full)
                            DaysCountdownView(endDate: .now.addingTimeInterval(14 * 86400), style: .compact)
                            DaysCountdownView(endDate: .now.addingTimeInterval(60 * 86400), style: .full)
                            DaysCountdownView(endDate: .now.addingTimeInterval(365 * 86400), style: .compact)
                        }
                    }

                    group("Appliance icons") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 16)], spacing: 16) {
                            ForEach(ApplianceCategory.allCases, id: \.self) { c in
                                VStack(spacing: 6) {
                                    CategoryIconView(category: c)
                                    Text(c.rawValue).font(.caption2)
                                }
                            }
                        }
                    }

                    group("Expiry icons") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 16)], spacing: 16) {
                            ForEach(ExpiryCategory.allCases, id: \.self) { c in
                                VStack(spacing: 6) {
                                    ExpiryCategoryIconView(category: c)
                                    Text(c.rawValue).font(.caption2)
                                }
                            }
                        }
                    }

                    group("Section headers") {
                        VStack(spacing: 12) {
                            SectionHeader("Recent warranties")
                            SectionHeader("Expiring soon", action: {})
                        }
                    }

                    group("Buttons") {
                        VStack(spacing: 12) {
                            PrimaryButton(title: "Primary", isLoading: isLoadingPrimary) {
                                isLoadingPrimary.toggle()
                            }
                            SecondaryButton(title: "Secondary", action: {})
                            HStack {
                                Spacer()
                                FloatingActionButton(action: {})
                            }
                        }
                    }

                    group("Skeleton row") {
                        VStack(spacing: 0) {
                            SkeletonRow()
                            Divider()
                            SkeletonRow()
                        }
                    }

                    group("Confirm delete") {
                        Button {
                            showDeleteDialog = true
                        } label: {
                            Text("Show delete dialog")
                                .foregroundStyle(Color.accentTeal)
                        }
                        .confirmDelete(
                            isPresented: $showDeleteDialog,
                            itemName: "Washing Machine",
                            onConfirm: {}
                        )
                    }

                    group("Empty state") {
                        EmptyStateView(
                            icon: "tray",
                            title: "No appliances yet",
                            subtitle: "Add your first appliance to start tracking warranties",
                            actionLabel: "Add appliance",
                            action: {}
                        )
                        .frame(height: 320)
                    }
                }
                .padding()
            }
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title)
            content()
        }
    }
}

#Preview {
    ComponentsPreview()
}
