import SwiftUI
import UIKit

struct ExpiryCategoryGrid: View {
    @Bindable var viewModel: AddExpiryViewModel
    let onAdvance: () -> Void

    private let descriptions: [ExpiryCategory: String] = [
        .document: "Passports, licenses, IDs",
        .medication: "Prescriptions, supplements",
        .food: "Pantry, perishables",
        .subscription: "Annual services, memberships",
        .insurance: "Policies, coverage",
        .vehicle: "Registration, MOT, tax",
        .other: "Anything else"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you tracking?")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text("Pick a category to get smart reminders")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(ExpiryCategory.allCases, id: \.self) { category in
                        categoryCard(category)
                    }
                }
            }
            .padding(24)
        }
    }

    private func categoryCard(_ category: ExpiryCategory) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            viewModel.applySmartDefaults(for: category)
            onAdvance()
        } label: {
            VStack(spacing: 12) {
                ExpiryCategoryIconView(category: category, size: 56)
                Text(displayName(for: category))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text(descriptions[category] ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private func displayName(for category: ExpiryCategory) -> String {
        switch category {
        case .document: "Document"
        case .medication: "Medication"
        case .food: "Food"
        case .subscription: "Subscription"
        case .insurance: "Insurance"
        case .vehicle: "Vehicle"
        case .other: "Other"
        }
    }
}
