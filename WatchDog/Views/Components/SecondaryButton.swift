import SwiftUI
import UIKit

struct SecondaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.accentTeal)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.accentTeal)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule().stroke(Color.accentTeal, lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Loading", isLoading: true, action: {})
    }
    .padding()
}
