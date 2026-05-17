import SwiftUI

struct ExpiryDetailsForm: View {
    @Bindable var viewModel: AddExpiryViewModel
    let onChangeCategory: () -> Void

    @State private var showNotesField: Bool = false

    private let recurrenceOptions: [(label: String, months: Int)] = [
        ("1 month", 1), ("3 months", 3), ("6 months", 6),
        ("1 year", 12), ("2 years", 24), ("5 years", 60), ("10 years", 120)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                categoryHeader
                nameField
                expiryDateSection
                remindersSection
                recurringSection
                notesSection
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if !viewModel.notes.isEmpty { showNotesField = true }
        }
    }

    @ViewBuilder
    private var categoryHeader: some View {
        if let category = viewModel.category {
            HStack(spacing: 12) {
                ExpiryCategoryIconView(category: category, size: 32)
                Text(displayName(for: category))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Spacer()
                Button("Change", action: onChangeCategory)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
            }
            .padding(.bottom, 4)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Name *")
            TextField(
                viewModel.placeholderName(for: viewModel.category),
                text: $viewModel.name
            )
            .font(.system(size: 17))
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var expiryDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("When does it expire?")
            DatePicker(
                "",
                selection: $viewModel.expiryDate,
                in: Date.now...,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.graphical)
            .tint(Color.accentTeal)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Remind me")
            VStack(spacing: 0) {
                reminderToggle(label: "30 days before", binding: $viewModel.reminder30Days)
                divider
                reminderToggle(label: "7 days before", binding: $viewModel.reminder7Days)
                divider
                reminderToggle(label: "1 day before", binding: $viewModel.reminder1Day)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.isRecurring) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This renews regularly")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text("We'll suggest a new date on renewal")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.accentTeal)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )

            if viewModel.isRecurring {
                Picker("Renews every", selection: $viewModel.recurrenceMonths) {
                    ForEach(recurrenceOptions, id: \.months) { option in
                        Text(option.label).tag(option.months)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.accentTeal)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showNotesField.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showNotesField ? "minus" : "plus")
                    Text(showNotesField ? "Hide notes" : "Add notes")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.accentTeal)
            }
            .buttonStyle(.plain)

            if showNotesField {
                TextEditor(text: $viewModel.notes)
                    .font(.system(size: 17))
                    .padding(8)
                    .frame(minHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .scrollContentBackground(.hidden)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.05)
            .foregroundStyle(.secondary)
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
