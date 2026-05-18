import Foundation
import Sentry

/// Thin wrapper around Sentry. Configured once at launch; failures are
/// silent in DEBUG so a missing DSN never blocks local development.
enum CrashReporter {
    private(set) static var isConfigured: Bool = false

    static func configure() {
        guard let dsn = readPlistString("SENTRY_DSN"), !dsn.isEmpty else {
            #if DEBUG
            print("[CrashReporter] SENTRY_DSN missing or empty in Config.plist — skipping")
            #else
            NSLog("[CrashReporter] SENTRY_DSN missing in Release build")
            #endif
            return
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let environment: String = {
            #if DEBUG
            return "development"
            #else
            return "production"
            #endif
        }()

        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 0.1
            options.environment = environment
            options.releaseName = "watchdog@\(version)"
            #if DEBUG
            options.debug = true
            #endif
        }
        isConfigured = true
    }

    static func setUser(id: String?, email: String? = nil) {
        guard isConfigured else { return }
        if let id {
            let user = User(userId: id)
            if let email { user.email = email }
            SentrySDK.setUser(user)
        } else {
            SentrySDK.setUser(nil)
        }
    }

    static func logError(_ error: Error, context: [String: Any]? = nil) {
        guard isConfigured else { return }
        SentrySDK.capture(error: error) { scope in
            if let context {
                scope.setContext(value: context, key: "details")
            }
        }
    }

    static func logMessage(_ message: String, level: SentryLevel = .info) {
        guard isConfigured else { return }
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
    }

    private static func readPlistString(_ key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any],
              let value = plist[key] as? String
        else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
