import SwiftUI
import UIKit

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Circle()
                .fill(Color.accentTeal)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingActionButton(action: {})
            .padding(20)
    }
}
