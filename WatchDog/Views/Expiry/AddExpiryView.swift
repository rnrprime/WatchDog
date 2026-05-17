import SwiftUI
import SwiftData

struct AddExpiryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = AddExpiryViewModel()
    @State private var isSaving = false
    @State private var saveError: String? = nil
    @State private var showDiscardAlert = false
    @State private var previousStep = 1

    private var hasAnyEntry: Bool {
        viewModel.category != nil || !viewModel.name.isEmpty || !viewModel.notes.isEmpty
    }

    private var isMovingForward: Bool { viewModel.step >= previousStep }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    stepContent
                        .id(viewModel.step)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: isMovingForward ? .trailing : .leading)
                                    .combined(with: .opacity),
                                removal: .move(edge: isMovingForward ? .leading : .trailing)
                                    .combined(with: .opacity)
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .animation(.easeInOut(duration: 0.3), value: viewModel.step)

                if viewModel.step == 2 {
                    PrimaryButton(
                        title: "Save",
                        isLoading: isSaving
                    ) {
                        performSave()
                    }
                    .disabled(!viewModel.canSave || isSaving)
                    .opacity(viewModel.canSave ? 1 : 0.5)
                    .padding(16)
                    .background(Color(.systemBackground))
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("New expiry item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasAnyEntry {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentTeal)
                    }
                    .disabled(isSaving)
                }
                if viewModel.step == 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            previousStep = viewModel.step
                            viewModel.step = 1
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.accentTeal)
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Your entries will be lost.")
            }
            .alert("Couldn't save", isPresented: errorBinding) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .interactiveDismissDisabled(hasAnyEntry)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case 1:
            ExpiryCategoryGrid(viewModel: viewModel) {
                previousStep = viewModel.step
                viewModel.step = 2
            }
        case 2:
            ExpiryDetailsForm(viewModel: viewModel) {
                previousStep = viewModel.step
                viewModel.step = 1
            }
        default:
            EmptyView()
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })
    }

    private func performSave() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                _ = try await viewModel.save(to: modelContext)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
