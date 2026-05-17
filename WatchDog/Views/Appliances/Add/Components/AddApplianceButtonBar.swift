import SwiftUI

struct AddApplianceButtonBar: View {
    let currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let isSaving: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    private var isLastStep: Bool { currentStep == totalSteps }

    private var primaryTitle: String {
        isLastStep ? "Save appliance" : "Continue"
    }

    var body: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                SecondaryButton(title: "Back", action: onBack)
                    .frame(maxWidth: 120)
                    .disabled(isSaving)
            }

            PrimaryButton(
                title: primaryTitle,
                isLoading: isSaving && isLastStep,
                action: onNext
            )
            .frame(maxWidth: .infinity)
            .disabled(!canProceed || isSaving)
            .opacity(canProceed ? 1 : 0.5)
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
}
