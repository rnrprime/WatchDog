import SwiftUI
import SwiftData

struct AddApplianceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = AddApplianceViewModel()
    @State private var showConfetti = false
    @State private var saveError: String? = nil
    @State private var isSaving = false
    @State private var showDiscardAlert = false
    @State private var previousStep: Int = 1

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case 1: viewModel.entryMethod != nil
        case 2: viewModel.canProceedFromStep2
        case 3: viewModel.canProceedFromStep3
        default: true
        }
    }

    private var isMovingForward: Bool {
        viewModel.currentStep >= previousStep
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepIndicator(
                    currentStep: viewModel.currentStep,
                    totalSteps: viewModel.totalSteps
                )

                ZStack {
                    stepContent
                        .id(viewModel.currentStep)
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
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                AddApplianceButtonBar(
                    currentStep: viewModel.currentStep,
                    totalSteps: viewModel.totalSteps,
                    canProceed: canProceed,
                    isSaving: isSaving,
                    onBack: handleBack,
                    onNext: handleNext
                )
            }
            .background(Color(.systemBackground))
            .navigationTitle("Add appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.hasAnyEntry {
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
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.hasAnyEntry)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            Step1_EntryMethod(viewModel: viewModel) {
                advance()
            }
        case 2:
            Step2_ApplianceForm(viewModel: viewModel)
        case 3:
            Step3_WarrantyForm(viewModel: viewModel)
        case 4:
            Step4_Documents(viewModel: viewModel) {
                advance()
            }
        case 5:
            Step5_Confirm(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private func handleBack() {
        previousStep = viewModel.currentStep
        viewModel.previousStep()
    }

    private func handleNext() {
        if viewModel.currentStep == viewModel.totalSteps {
            performSave()
        } else {
            advance()
        }
    }

    private func advance() {
        previousStep = viewModel.currentStep
        viewModel.nextStep()
    }

    private func performSave() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                _ = try await viewModel.save(to: modelContext)
                withAnimation(.easeOut(duration: 0.25)) { showConfetti = true }
                try? await Task.sleep(nanoseconds: 600_000_000)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}

private struct ConfettiView: View {
    private struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: Double
        let radius: Double
        let color: Color
    }

    @State private var startDate: Date = .now

    private let particles: [Particle] = {
        let palette: [Color] = [
            .accentTeal,
            Color(red: 0.95, green: 0.6, blue: 0.2),
            Color(red: 0.95, green: 0.3, blue: 0.4),
            Color(red: 0.4, green: 0.7, blue: 0.95),
            Color(red: 0.9, green: 0.8, blue: 0.2)
        ]
        return (0..<50).map { _ in
            Particle(
                angle: .random(in: 0..<(2 * .pi)),
                distance: .random(in: 140...280),
                radius: .random(in: 3...7),
                color: palette.randomElement() ?? .accentTeal
            )
        }
    }()

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                let elapsed = context.date.timeIntervalSince(startDate)
                let duration: TimeInterval = 0.8
                guard elapsed < duration else { return }
                let progress = elapsed / duration
                let alpha = 1.0 - progress
                let centerX = size.width / 2
                let centerY = size.height / 2

                for particle in particles {
                    let dx = cos(particle.angle) * particle.distance * progress
                    let dy = sin(particle.angle) * particle.distance * progress
                    let x = centerX + dx
                    let y = centerY + dy
                    let rect = CGRect(
                        x: x - particle.radius,
                        y: y - particle.radius,
                        width: particle.radius * 2,
                        height: particle.radius * 2
                    )
                    canvas.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(alpha))
                    )
                }
            }
        }
        .onAppear { startDate = .now }
    }
}
