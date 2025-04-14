

import SwiftData
import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func scheduleLocalNotification(for notification: NotificationModel) {
        guard !notification.isRead else { return }

        let content = UNMutableNotificationContent()

        switch notification.type {
        case .friendRequest:
            if let request = notification.data as? FriendRequest {
                content.title = "Friend Request"
                content.body = "@\(request.sender_handle) wants to be your friend"
                content.sound = .default
            }
        case .groupInvite:
            content.title = "Group Invite"
            content.body = "You've been invited to join a group"
            content.sound = .default
        case .deadline:
            if let task = notification.data as? taskapeTask {
                content.title = "Deadline Approaching"
                content.body = "\(task.name) is due soon"
                content.sound = .default
            }
        case .confirmationRequest:
            if let task = notification.data as? taskapeTask {
                content.title = "Task Confirmation"
                content.body = "Task \(task.name) requires your confirmation"
                content.sound = .default
            }
        case .eventLike:
            if let event = notification.data as? taskapeEvent {
                content.title = "New Event Like"
                content.body = "Someone liked your event"
                content.sound = .default
            }
        case .eventComment:
            if let event = notification.data as? taskapeEvent {
                content.title = "New Event Comment"
                content.body = "Someone commented on your event"
                content.sound = .default
            }
        }

        let identifier = "taskape.notification.\(notification.id)"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func scheduleLocalNotificationsForUnread(notifications: [NotificationModel]) {
        let unreadNotifications = notifications.filter { !$0.isRead }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for notification in unreadNotifications {
            scheduleLocalNotification(for: notification)
        }

        UIApplication.shared.applicationIconBadgeNumber = unreadNotifications.count
    }

    func setupBackgroundRefresh() {}

    func performBackgroundRefresh(modelContext: ModelContext, completion: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                NotificationStore.shared.refreshNotifications(modelContext: modelContext) {
                    self.scheduleLocalNotificationsForUnread(notifications: NotificationStore.shared.notifications)
                    continuation.resume()
                }
            }

            completion(.newData)
        }
    }
}
