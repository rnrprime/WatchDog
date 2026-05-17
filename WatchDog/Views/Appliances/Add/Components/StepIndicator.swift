import SwiftUI

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                stepCircle(step)
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.accentTeal : Color(.separator))
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func stepCircle(_ step: Int) -> some View {
        Group {
            if step < currentStep {
                Circle()
                    .fill(Color.accentTeal)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    )
            } else if step == currentStep {
                Circle()
                    .fill(Color.accentTeal)
                    .overlay(
                        Text("\(step)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            } else {
                Circle()
                    .stroke(Color(.separator), lineWidth: 1.5)
                    .overlay(
                        Text("\(step)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 24, height: 24)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

#Preview {
    VStack(spacing: 24) {
        StepIndicator(currentStep: 1, totalSteps: 5)
        StepIndicator(currentStep: 3, totalSteps: 5)
        StepIndicator(currentStep: 5, totalSteps: 5)
    }
}
