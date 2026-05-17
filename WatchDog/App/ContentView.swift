import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isGuestMode") private var isGuestMode = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingPlaceholderView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

private struct OnboardingPlaceholderView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Onboarding placeholder")
                .font(.title2)
                .foregroundStyle(Color(.label))
            Spacer()
            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.06, green: 0.43, blue: 0.34))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
