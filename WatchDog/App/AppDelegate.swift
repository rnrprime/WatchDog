import UIKit
import UserNotifications
import Supabase

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationService.shared.deviceToken = hex
        #if DEBUG
        print("[Push] device token: \(hex)")
        #endif

        Task { await uploadDeviceToken(hex) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("[Push] register failed: \(error)")
        #endif
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let destination = NotificationService.shared.handleNotificationTap(userInfo: userInfo) {
            NotificationService.shared.pendingDestination = destination
        }
    }

    private func uploadDeviceToken(_ token: String) async {
        guard let userId = SupabaseService.shared.currentUser?.id else { return }
        guard !UserDefaults.standard.bool(forKey: "isGuestMode") else { return }

        struct DeviceTokenPayload: Codable {
            let user_id: String
            let apns_token: String
            let os_version: String?
            let device_name: String?
        }

        let payload = DeviceTokenPayload(
            user_id: userId.uuidString,
            apns_token: token,
            os_version: UIDevice.current.systemVersion,
            device_name: UIDevice.current.name
        )

        do {
            try await SupabaseService.shared.client
                .from("device_tokens")
                .upsert(payload, onConflict: "apns_token")
                .execute()
        } catch {
            #if DEBUG
            print("[Push] device token upload failed: \(error)")
            #endif
        }
    }
}
