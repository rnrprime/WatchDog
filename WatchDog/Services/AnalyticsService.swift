import Foundation
import PostHog

@Observable
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private(set) var isConfigured: Bool = false

    private init() {
        configure()
    }

    private func configure() {
        guard let apiKey = readPlistString("POSTHOG_API_KEY"), !apiKey.isEmpty else {
            #if DEBUG
            print("[Analytics] POSTHOG_API_KEY missing — skipping setup")
            #endif
            return
        }
        let host = readPlistString("POSTHOG_HOST")?.nilIfEmpty ?? "https://us.i.posthog.com"

        let config = PostHogConfig(projectToken: apiKey, host: host)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false

        PostHogSDK.shared.setup(config)
        isConfigured = true
    }

    func identify(userId: String, properties: [String: Any]? = nil) {
        guard isConfigured else { return }
        if let properties {
            PostHogSDK.shared.identify(userId, userProperties: properties)
        } else {
            PostHogSDK.shared.identify(userId)
        }
    }

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard isConfigured else {
            #if DEBUG
            print("[Analytics] (dry) \(event.name) \(event.defaultProperties)")
            #endif
            return
        }
        let merged = event.defaultProperties.merging(properties ?? [:]) { _, b in b }
        if merged.isEmpty {
            PostHogSDK.shared.capture(event.name)
        } else {
            PostHogSDK.shared.capture(event.name, properties: merged)
        }
    }

    func screen(_ screenName: String) {
        guard isConfigured else { return }
        PostHogSDK.shared.screen(screenName)
    }

    func reset() {
        guard isConfigured else { return }
        PostHogSDK.shared.reset()
    }

    private func readPlistString(_ key: String) -> String? {
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
