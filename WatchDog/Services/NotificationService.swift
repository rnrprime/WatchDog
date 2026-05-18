import Foundation
import UserNotifications
import UIKit

enum NotificationDestination {
    case appliance(UUID)
    case expiry(UUID)
    case none
}

@Observable
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var deviceToken: String? = nil
    var pendingDestination: NotificationDestination? = nil

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            #if DEBUG
            print("[Notifications] Authorization request failed: \(error)")
            #endif
            return false
        }
    }

    func scheduleWarrantyReminders(
        for appliance: Appliance,
        warranty: Warranty,
        reminderDays: [Int] = [90, 30, 7, 1]
    ) {
        let calendar = Calendar.current
        for days in reminderDays {
            guard let triggerDay = calendar.date(
                byAdding: .day, value: -days, to: warranty.endDate
            ) else { continue }
            guard triggerDay > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = appliance.name
            content.body = "Warranty expires in \(days) \(days == 1 ? "day" : "days")"
            content.sound = .default
            content.categoryIdentifier = "WARRANTY_REMINDER"
            content.userInfo = [
                "entityType": "warranty",
                "entityId": warranty.id.uuidString,
                "applianceId": appliance.id.uuidString
            ]

            var components = calendar.dateComponents(
                [.year, .month, .day], from: triggerDay
            )
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components, repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "warranty-\(warranty.id.uuidString)-\(days)d",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                #if DEBUG
                if let error { print("[Notifications] add failed: \(error)") }
                #endif
            }
        }
    }

    func scheduleExpiryReminders(for item: ExpiryItem, reminderDays: [Int]) {
        let calendar = Calendar.current
        for days in reminderDays {
            guard let triggerDay = calendar.date(
                byAdding: .day, value: -days, to: item.expiryDate
            ) else { continue }
            guard triggerDay > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = item.name
            content.body = days == 0
                ? "Expires today"
                : "Expires in \(days) \(days == 1 ? "day" : "days")"
            content.sound = .default
            content.categoryIdentifier = "EXPIRY_REMINDER"
            content.userInfo = [
                "entityType": "expiry",
                "entityId": item.id.uuidString
            ]

            var components = calendar.dateComponents(
                [.year, .month, .day], from: triggerDay
            )
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components, repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "expiry-\(item.id.uuidString)-\(days)d",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                #if DEBUG
                if let error { print("[Notifications] add failed: \(error)") }
                #endif
            }
        }
    }

    func cancelReminders(entityId: UUID) {
        let needle = entityId.uuidString
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let matches = requests
                .map(\.identifier)
                .filter { $0.contains(needle) }
            guard !matches.isEmpty else { return }
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: matches)
        }
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func pendingCount() async -> Int {
        await UNUserNotificationCenter.current().pendingNotificationRequests().count
    }

    func handleNotificationTap(userInfo: [AnyHashable: Any]) -> NotificationDestination? {
        guard let entityType = userInfo["entityType"] as? String,
              let entityIdString = userInfo["entityId"] as? String,
              let entityId = UUID(uuidString: entityIdString)
        else { return nil }

        switch entityType {
        case "warranty":
            AnalyticsService.shared.track(
                .reminderNotificationTapped(entityType: "warranty")
            )
            if let applianceIdString = userInfo["applianceId"] as? String,
               let applianceId = UUID(uuidString: applianceIdString) {
                return .appliance(applianceId)
            }
            return nil
        case "expiry":
            AnalyticsService.shared.track(
                .reminderNotificationTapped(entityType: "expiry")
            )
            return .expiry(entityId)
        default:
            return nil
        }
    }

    #if DEBUG
    func scheduleTestNotification(in seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Watchdog test"
        content.body = "Notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notifications] test add failed: \(error)") }
        }
    }
    #endif
}
