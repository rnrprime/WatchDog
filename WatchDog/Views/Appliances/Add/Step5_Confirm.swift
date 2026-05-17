import SwiftUI

struct Step5_Confirm: View {
    @Bindable var viewModel: AddApplianceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Almost done!")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text("Review and set up reminders")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                summaryCard

                if viewModel.hasWarranty {
                    remindersSection
                    notificationHint
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                if let category = viewModel.category {
                    CategoryIconView(category: category, size: 60)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.name.isEmpty ? "Untitled appliance" : viewModel.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    if !brandModelLine.isEmpty {
                        Text(brandModelLine)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            divider

            VStack(spacing: 8) {
                summaryRow(label: "Serial", value: viewModel.serialNumber.isEmpty ? nil : viewModel.serialNumber)
                summaryRow(
                    label: "Purchase date",
                    value: viewModel.purchaseDate.formatted(.dateTime.month(.abbreviated).day().year())
                )
                if !viewModel.purchasePrice.isEmpty {
                    summaryRow(label: "Purchase price", value: "$\(viewModel.purchasePrice)")
                }
                if !viewModel.store.isEmpty {
                    summaryRow(label: "Store", value: viewModel.store)
                }
            }

            divider

            if viewModel.hasWarranty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warranty: \(durationLabel)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text("Ends \(viewModel.computedWarrantyEndDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No warranty")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Reminders")
            VStack(spacing: 0) {
                reminderToggle(label: "90 days before expiry", binding: $viewModel.reminderNinetyDays)
                divider
                reminderToggle(label: "30 days before expiry", binding: $viewModel.reminderThirtyDays)
                divider
                reminderToggle(label: "7 days before expiry", binding: $viewModel.reminderSevenDays)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var notificationHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.accentTeal)
            Text("Reminders work better with notifications enabled. We'll ask after you save.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.accentTealLight.opacity(0.6))
        )
    }

    private func reminderToggle(label: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Color(.label))
        }
        .tint(Color.accentTeal)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func summaryRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "Not set")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(value == nil ? Color(.tertiaryLabel) : Color(.label))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
    }

    private var brandModelLine: String {
        var parts: [String] = []
        if !viewModel.brand.isEmpty { parts.append(viewModel.brand) }
        if !viewModel.model.isEmpty { parts.append(viewModel.model) }
        return parts.joined(separator: " · ")
    }

    private var durationLabel: String {
        switch viewModel.warrantyDurationOption {
        case .oneYear: "1 year"
        case .twoYears: "2 years"
        case .threeYears: "3 years"
        case .fiveYears: "5 years"
        case .custom: "\(viewModel.customDurationMonths) months"
        }
    }
}
