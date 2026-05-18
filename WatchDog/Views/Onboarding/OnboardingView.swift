import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 0
    @State private var trackedStart = false

    private let lastSlideIndex = 2

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage < lastSlideIndex {
                        Button("Skip") {
                            AnalyticsService.shared.track(.onboardingSkipped)
                            withAnimation {
                                currentPage = lastSlideIndex
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.accentTeal)
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }

                TabView(selection: $currentPage) {
                    OnboardingSlideView(
                        symbolName: "house.fill",
                        title: "Your home, remembered",
                        subtitle: "One app for every appliance, warranty, and expiry date in your home."
                    )
                    .tag(0)

                    OnboardingSlideView(
                        symbolName: "shield.checkered",
                        title: "Warranties. Passports. Everything.",
                        subtitle: "Track what matters and get reminded before it's too late.",
                        chips: ["Warranty reminders", "Passport expiry", "Receipt vault"]
                    )
                    .tag(1)

                    OnboardingSlideView(
                        symbolName: "lock.shield.fill",
                        title: "Your data stays yours",
                        subtitle: "End-to-end encrypted. No ads, ever. Delete anytime.",
                        checklist: [
                            "End-to-end encrypted",
                            "No ads, ever",
                            "Delete anytime"
                        ]
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .tint(Color.accentTeal)

                VStack {
                    if currentPage < lastSlideIndex {
                        PrimaryButton(title: "Next") {
                            withAnimation { currentPage += 1 }
                        }
                    } else {
                        NavigationLink {
                            AuthView()
                                .onAppear {
                                    AnalyticsService.shared.track(.onboardingCompleted)
                                }
                        } label: {
                            Text("Get started")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Capsule().fill(Color.accentTeal))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if !trackedStart {
                    AnalyticsService.shared.track(.onboardingStarted)
                    trackedStart = true
                }
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    OnboardingView()
}
