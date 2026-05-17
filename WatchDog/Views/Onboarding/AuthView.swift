import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AuthViewModel()
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                LinearGradient(
                    colors: [Color.accentTealLight, Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: proxy.size.height * 0.1)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            }

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentTeal)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 6) {
                    Text("Watchdog")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    Text("Takes care of your warranty & expiry")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.statusExpired)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            Task {
                                await viewModel.handleSignInWithApple(
                                    authorization: authorization,
                                    rawNonce: currentNonce
                                )
                            }
                        case .failure(let error):
                            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                                return
                            }
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(
                        colorScheme == .dark ? .whiteOutline : .black
                    )
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.isLoading)

                    SecondaryButton(
                        title: "Continue as guest",
                        isLoading: viewModel.isLoading
                    ) {
                        viewModel.continueAsGuest()
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 8)

                HStack(spacing: 16) {
                    Button("Privacy Policy") {}
                    Text("·").foregroundStyle(.secondary)
                    Button("Terms of Service") {}
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        AuthView()
    }
}
