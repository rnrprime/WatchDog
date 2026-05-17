import Foundation
import Supabase

enum SupabaseServiceError: LocalizedError {
    case notImplemented
    case missingConfiguration(String)
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Not implemented yet."
        case .missingConfiguration(let key):
            return "Missing configuration key in Config.plist: \(key)"
        case .invalidConfiguration(let key):
            return "Invalid configuration value for key: \(key)"
        }
    }
}

@Observable
@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient
    var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }

    private init() {
        let (url, anonKey) = Self.loadConfig()
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        Task { await self.checkSession() }
    }

    private static func loadConfig() -> (URL, String) {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any]
        else {
            fatalError("Config.plist not found in app bundle. See README/setup instructions.")
        }

        guard let urlString = plist["SUPABASE_URL"] as? String,
              !urlString.isEmpty,
              let url = URL(string: urlString)
        else {
            fatalError("Config.plist missing or invalid SUPABASE_URL.")
        }

        guard let anonKey = plist["SUPABASE_ANON_KEY"] as? String, !anonKey.isEmpty else {
            fatalError("Config.plist missing or empty SUPABASE_ANON_KEY.")
        }

        return (url, anonKey)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        throw SupabaseServiceError.notImplemented
    }

    func signOut() async throws {
        throw SupabaseServiceError.notImplemented
    }

    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
        } catch {
            self.currentUser = nil
        }
    }
}
