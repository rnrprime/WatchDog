import Foundation
import AuthenticationServices

@Observable
@MainActor
final class AuthViewModel {
    var isLoading: Bool = false
    var errorMessage: String?

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func handleSignInWithApple(authorization: ASAuthorization, rawNonce: String?) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Unexpected Apple credential type."
            return
        }
        guard let nonce = rawNonce else {
            errorMessage = "Missing nonce for Apple Sign In."
            return
        }
        guard let tokenData = credential.identityToken else {
            errorMessage = SupabaseServiceError.missingIdentityToken.errorDescription
            return
        }
        guard let idToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = SupabaseServiceError.invalidIdentityTokenEncoding.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
            UserDefaults.standard.set(false, forKey: "isGuestMode")
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        } catch {
            #if DEBUG
            print("[AuthViewModel] Apple sign in failed: \(error)")
            #endif
            errorMessage = error.localizedDescription
        }
    }

    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: "isGuestMode")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
