import SwiftUI

struct Step3_WarrantyForm: View {
    @Bindable var viewModel: AddApplianceViewModel

    @State private var showProviderFields: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Warranty details")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(.label))

                hasWarrantyToggle

                if viewModel.hasWarranty {
                    warrantyTypeSection
                    startDateSection
                    durationSection
                    endDateSummary
                    providerSection
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var hasWarrantyToggle: some View {
        Toggle(isOn: $viewModel.hasWarranty) {
            VStack(alignment: .leading, spacing: 2) {
                Text("This product has a warranty")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Text("You can add this later if you're not sure")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.accentTeal))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var warrantyTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Warranty type")
            Picker("Warranty type", selection: $viewModel.warrantyType) {
                Text("Manufacturer").tag(WarrantyType.manufacturer)
                Text("Extended").tag(WarrantyType.extended)
                Text("Both").tag(WarrantyType.both)
            }
            .pickerStyle(.segmented)
        }
    }

    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Warranty starts")
            DatePicker(
                "",
                selection: $viewModel.warrantyStartDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Color.accentTeal)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("How long is the warranty?")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AddApplianceViewModel.DurationOption.allCases) { option in
                        durationChip(option)
                    }
                }
            }
            if viewModel.warrantyDurationOption == .custom {
                HStack {
                    Text("\(viewModel.customDurationMonths) months")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(.label))
                    Spacer()
                    Stepper(
                        "",
                        value: $viewModel.customDurationMonths,
                        in: 1...240
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    private func durationChip(_ option: AddApplianceViewModel.DurationOption) -> some View {
        let isActive = viewModel.warrantyDurationOption == option
        return Button {
            viewModel.warrantyDurationOption = option
        } label: {
            Text(option.displayLabel)
                .font(.system(size: 14, weight: isActive ? .semibold : .medium))
                .foregroundStyle(isActive ? Color.white : Color(.label))
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(isActive ? Color.accentTeal : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }

    private var endDateSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Ends")
            Text(viewModel.computedWarrantyEndDate, format:
                .dateTime.weekday(.wide).month(.wide).day().year()
            )
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color(.label))

            Text("in \(relativeOffset(viewModel.computedWarrantyEndDate))")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentTealLight))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showProviderFields.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showProviderFields ? "minus" : "plus")
                    Text(showProviderFields ? "Hide warranty provider" : "Add warranty provider")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.accentTeal)
            }
            .buttonStyle(.plain)

            if showProviderFields {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Provider")
                        styledTextField(placeholder: "e.g. SquareTrade", text: $viewModel.provider)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Contact info")
                        styledTextField(placeholder: "Phone, email, or URL", text: $viewModel.providerContact)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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

    private func relativeOffset(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: .now, to: date)
        let years = parts.year ?? 0
        let months = parts.month ?? 0
        if years <= 0 && months <= 0 { return "less than a month" }
        if years == 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        if months == 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        }
        return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s")"
    }
}
