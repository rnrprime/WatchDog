import SwiftUI
import UIKit

struct Step2_ApplianceForm: View {
    @Bindable var viewModel: AddApplianceViewModel

    private let brandSuggestions = [
        "Samsung", "LG", "Sony", "Bosch", "Whirlpool", "Daikin",
        "Mitsubishi", "Panasonic", "Philips", "Dyson", "Apple",
        "Xiaomi", "Haier"
    ]

    private var filteredBrandSuggestions: [String] {
        let needle = viewModel.brand
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
        guard !needle.isEmpty else { return [] }
        return brandSuggestions.filter {
            $0.lowercased().hasPrefix(needle) && $0.lowercased() != needle
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What is it?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(.label))

                categorySection
                nameField
                brandSection
                modelField
                serialField
                purchaseDateField
                advancedSection
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Category *")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                ForEach(ApplianceCategory.allCases, id: \.self) { category in
                    categoryTile(category)
                }
            }
        }
    }

    private func categoryTile(_ category: ApplianceCategory) -> some View {
        let isSelected = viewModel.category == category
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            viewModel.category = category
        } label: {
            VStack(spacing: 6) {
                CategoryIconView(category: category, size: 48)
                Text(displayName(for: category))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.accentTeal : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Name *")
            styledTextField(placeholder: "e.g. Kitchen Fridge", text: $viewModel.name)
        }
    }

    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Brand")
            styledTextField(placeholder: "e.g. Samsung", text: $viewModel.brand)
            if !filteredBrandSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filteredBrandSuggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.brand = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.accentTeal)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.accentTealLight))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var modelField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Model")
            styledTextField(placeholder: "e.g. RT38K5562SL", text: $viewModel.model)
        }
    }

    private var serialField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Serial number")
            styledTextField(placeholder: "e.g. SR2024X1", text: $viewModel.serialNumber)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
    }

    private var purchaseDateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Purchase date")
            DatePicker(
                "",
                selection: $viewModel.purchaseDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Color.accentTeal)
        }
    }

    @ViewBuilder
    private var advancedSection: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.showAdvancedFields.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.showAdvancedFields ? "minus" : "plus")
                Text(viewModel.showAdvancedFields ? "Hide purchase details" : "Add purchase details")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.accentTeal)
        }
        .buttonStyle(.plain)

        if viewModel.showAdvancedFields {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Purchase price")
                    HStack(spacing: 8) {
                        Text("$")
                            .font(.system(size: 17))
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $viewModel.purchasePrice)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 17))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Store")
                    styledTextField(placeholder: "Where did you buy it?", text: $viewModel.store)
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Notes")
                    TextEditor(text: $viewModel.notes)
                        .font(.system(size: 17))
                        .padding(8)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .scrollContentBackground(.hidden)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func styledTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 17))
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.05)
            .foregroundStyle(.secondary)
    }

    private func displayName(for category: ApplianceCategory) -> String {
        switch category {
        case .kitchen: "Kitchen"
        case .laundry: "Laundry"
        case .electronics: "Electronics"
        case .hvac: "HVAC"
        case .outdoor: "Outdoor"
        case .other: "Other"
        }
    }
}
