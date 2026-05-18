import Foundation
import RevenueCat
import Supabase
import Auth
import PostgREST

@Observable
@MainActor
final class RevenueCatService {
    static let shared = RevenueCatService()

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var isConfigured: Bool = false
    var isLoading: Bool = false
    var purchaseError: String?

    var isPro: Bool {
        customerInfo?.entitlements["pro"]?.isActive == true
    }

    private static let entitlementId = "pro"

    private init() {
        configure()
        if isConfigured {
            Task {
                await self.fetchOfferings()
                await self.fetchCustomerInfo()
            }
        }
    }

    private func configure() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any],
              let apiKey = plist["REVENUECAT_API_KEY"] as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            #if DEBUG
            print("[RevenueCat] REVENUECAT_API_KEY missing or empty in Config.plist — skipping configure")
            #endif
            return
        }

        #if DEBUG
        Purchases.logLevel = .info
        #else
        Purchases.logLevel = .warn
        #endif

        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
    }

    func fetchOfferings() async {
        guard isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
        } catch {
            #if DEBUG
            print("[RevenueCat] offerings fetch failed: \(error)")
            #endif
        }
    }

    func fetchCustomerInfo() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
        } catch {
            #if DEBUG
            print("[RevenueCat] customerInfo fetch failed: \(error)")
            #endif
        }
    }

    /// Returns the default offering, falling back to the first available offering.
    var defaultOffering: Offering? {
        if let current = offerings?.current { return current }
        if let first = offerings?.all.first?.value { return first }
        return nil
    }

    /// Purchase a package. Returns `true` if completed, `false` if user cancelled (silent).
    /// Throws on real errors.
    @discardableResult
    func purchase(package: Package) async throws -> Bool {
        guard isConfigured else {
            throw NSError(
                domain: "RevenueCat",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Subscriptions aren't available right now."]
            )
        }
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { return false }

        self.customerInfo = result.customerInfo
        await syncSubscriptionToSupabase()
        AnalyticsService.shared.track(
            .subscriptionPurchased(plan: planLabel(for: package))
        )
        return true
    }

    private func planLabel(for package: Package) -> String {
        switch package.packageType {
        case .annual: "annual"
        case .monthly: "monthly"
        case .sixMonth: "six_month"
        case .threeMonth: "three_month"
        case .twoMonth: "two_month"
        case .weekly: "weekly"
        case .lifetime: "lifetime"
        default: package.identifier
        }
    }

    func restorePurchases() async throws {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        let info = try await Purchases.shared.restorePurchases()
        self.customerInfo = info
        await syncSubscriptionToSupabase()
        if isPro {
            AnalyticsService.shared.track(.subscriptionRestored)
        }
    }

    func identify(userId: String) async {
        guard isConfigured else { return }
        do {
            let (info, _) = try await Purchases.shared.logIn(userId)
            self.customerInfo = info
            await syncSubscriptionToSupabase()
        } catch {
            #if DEBUG
            print("[RevenueCat] logIn failed: \(error)")
            #endif
        }
    }

    func logout() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.logOut()
            self.customerInfo = info
        } catch {
            #if DEBUG
            print("[RevenueCat] logOut failed: \(error)")
            #endif
        }
    }

    /// Writes subscription state to Supabase `profiles` row so the cloud
    /// reflects the user's current tier and RevenueCat customer id.
    private func syncSubscriptionToSupabase() async {
        guard !UserDefaults.standard.bool(forKey: "isGuestMode") else { return }
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        guard let info = customerInfo else { return }

        let tier: String = info.entitlements[Self.entitlementId]?.isActive == true ? "pro" : "free"
        let payload = ProfileSubscriptionPayload(
            subscription_tier: tier,
            rc_customer_id: info.originalAppUserId
        )

        do {
            try await SupabaseService.shared.client
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            #if DEBUG
            print("[RevenueCat] profile sync failed: \(error)")
            #endif
        }
    }
}

private struct ProfileSubscriptionPayload: Encodable {
    let subscription_tier: String
    let rc_customer_id: String
}
