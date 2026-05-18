import SwiftUI
import RevenueCat

struct PaywallView: View {
    let trigger: PaywallTrigger?
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var revenueCat = RevenueCatService.shared

    @State private var selectedPackage: Package?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccessToast = false

    init(trigger: PaywallTrigger? = nil, onDismiss: @escaping () -> Void = {}) {
        self.trigger = trigger
        self.onDismiss = onDismiss
    }

    private var monthlyPackage: Package? {
        revenueCat.defaultOffering?.monthly
            ?? revenueCat.defaultOffering?.availablePackages.first(where: {
                $0.packageType == .monthly
            })
    }

    private var annualPackage: Package? {
        revenueCat.defaultOffering?.annual
            ?? revenueCat.defaultOffering?.availablePackages.first(where: {
                $0.packageType == .annual
            })
    }

    private var headline: String { trigger?.headline ?? "Upgrade to Pro" }
    private var subheadline: String {
        trigger?.subheadline ?? "Unlock everything Watchdog has to offer"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    featuresSection
                    pricingSection
                    actionsSection
                    finePrint
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task(id: revenueCat.isConfigured) {
                if revenueCat.offerings == nil {
                    await revenueCat.fetchOfferings()
                }
                if selectedPackage == nil {
                    selectedPackage = annualPackage ?? monthlyPackage
                }
            }
            .onAppear {
                AnalyticsService.shared.track(
                    .paywallViewed(trigger: trigger?.id ?? "generic")
                )
            }
            .alert("Something went wrong", isPresented: $showError) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                Text("Welcome to Pro!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentTeal))
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(Color.accentTeal)
                .padding(.top, 8)

            Text(headline)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(subheadline)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(
                title: "Unlimited appliances",
                subtitle: "Track every appliance, no caps"
            )
            FeatureRow(
                title: "Smart receipt scanning",
                subtitle: "Auto-fill purchase data with one photo"
            )
            FeatureRow(
                title: "Cloud backup",
                subtitle: "Access your data from any device"
            )
            FeatureRow(
                title: "All expiry categories",
                subtitle: "Passports, medications, subscriptions, and more"
            )
            FeatureRow(
                title: "Priority support",
                subtitle: "We respond within 24 hours"
            )
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var pricingSection: some View {
        if monthlyPackage != nil || annualPackage != nil {
            HStack(spacing: 12) {
                if let monthly = monthlyPackage {
                    PricingCard(
                        tier: "Monthly",
                        price: monthly.storeProduct.localizedPriceString,
                        period: "/ month",
                        badge: nil,
                        isSelected: selectedPackage?.identifier == monthly.identifier
                    ) {
                        selectedPackage = monthly
                    }
                }
                if let annual = annualPackage {
                    PricingCard(
                        tier: "Annual",
                        price: annual.storeProduct.localizedPriceString,
                        period: "/ year",
                        badge: "Save 40%",
                        isSelected: selectedPackage?.identifier == annual.identifier
                    ) {
                        selectedPackage = annual
                    }
                }
            }
        } else if !revenueCat.isConfigured {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Subscriptions aren't configured yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(20)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: subscribeButtonTitle,
                isLoading: revenueCat.isLoading
            ) {
                Task { await purchaseSelected() }
            }
            .disabled(selectedPackage == nil || revenueCat.isLoading)

            Button {
                Task { await restore() }
            } label: {
                Text("Restore purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentTeal)
            }
            .disabled(revenueCat.isLoading)
        }
    }

    private var subscribeButtonTitle: String {
        if let trial = selectedPackage?.storeProduct.introductoryDiscount,
           trial.paymentMode == .freeTrial {
            return "Start free trial"
        }
        return "Subscribe"
    }

    private var finePrint: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Cancel anytime in Settings → Apple ID → Subscriptions. Auto-renews until cancelled.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 14) {
                Button("Terms of Service") {
                    openURL("https://watchdog.app/terms")
                }
                Text("·").foregroundStyle(.secondary)
                Button("Privacy Policy") {
                    openURL("https://watchdog.app/privacy")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.accentTeal)
        }
        .padding(.horizontal, 4)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .accessibilityLabel("Close")
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func purchaseSelected() async {
        guard let package = selectedPackage else { return }
        do {
            let completed = try await revenueCat.purchase(package: package)
            if completed {
                withAnimation(.spring(duration: 0.3)) { showSuccessToast = true }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.spring(duration: 0.3)) { showSuccessToast = false }
                onDismiss()
                dismiss()
            }
        } catch {
            errorMessage = friendlyError(error)
            showError = true
        }
    }

    private func restore() async {
        do {
            try await revenueCat.restorePurchases()
            if revenueCat.isPro {
                withAnimation(.spring(duration: 0.3)) { showSuccessToast = true }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.spring(duration: 0.3)) { showSuccessToast = false }
                onDismiss()
                dismiss()
            } else {
                errorMessage = "No active subscription found on this Apple ID."
                showError = true
            }
        } catch {
            errorMessage = friendlyError(error)
            showError = true
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let ns = error as NSError
        if let code = ErrorCode(rawValue: ns.code) {
            switch code {
            case .networkError:
                return "Network issue — please check your connection and try again."
            case .paymentPendingError:
                return "Your payment is pending approval. We'll unlock Pro once it clears."
            case .productNotAvailableForPurchaseError:
                return "This subscription isn't available right now."
            case .storeProblemError:
                return "The App Store had a problem completing this purchase. Please try again."
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
