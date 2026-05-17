import SwiftUI
import UIKit

struct ExpiryCategoryFilterChips: View {
    @Bindable var viewModel: ExpiryListViewModel
    let items: [ExpiryItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", category: nil)
                ForEach(ExpiryCategory.allCases, id: \.self) { category in
                    chip(label: displayName(for: category), category: category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func chip(label: String, category: ExpiryCategory?) -> some View {
        let isActive = viewModel.selectedCategory == category
        let count = viewModel.categoryCount(for: category, in: items)
        let urgent = viewModel.urgentCountForCategory(category: category, in: items)

        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .foregroundStyle(isActive ? Color.white : Color(.label))
            .background(
                Capsule()
                    .fill(isActive ? Color.accentTeal : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isActive ? Color.clear : Color(.separator),
                        lineWidth: 0.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if urgent > 0 {
                    Circle()
                        .fill(Color.statusExpired)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func displayName(for category: ExpiryCategory) -> String {
        switch category {
        case .document: "Documents"
        case .medication: "Medication"
        case .food: "Food"
        case .subscription: "Subscriptions"
        case .insurance: "Insurance"
        case .vehicle: "Vehicle"
        case .other: "Other"
        }
    }
}
