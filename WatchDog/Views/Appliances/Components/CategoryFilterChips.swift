import SwiftUI
import UIKit

struct CategoryFilterChips: View {
    @Bindable var viewModel: ApplianceListViewModel
    let appliances: [Appliance]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", category: nil)
                ForEach(ApplianceCategory.allCases, id: \.self) { category in
                    chip(label: categoryLabel(category), category: category)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func chip(label: String, category: ApplianceCategory?) -> some View {
        let isActive = viewModel.selectedCategory == category
        let count = viewModel.categoryCount(for: category, in: appliances)

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
        }
        .buttonStyle(.plain)
    }

    private func categoryLabel(_ c: ApplianceCategory) -> String {
        switch c {
        case .kitchen: "Kitchen"
        case .laundry: "Laundry"
        case .electronics: "Electronics"
        case .hvac: "HVAC"
        case .outdoor: "Outdoor"
        case .other: "Other"
        }
    }
}
