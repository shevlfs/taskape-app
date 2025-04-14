import BackgroundTasks
import SwiftData
import SwiftUI

import BackgroundTasks
import SwiftData
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        registerBackgroundTasks()

        NotificationManager.shared.requestNotificationPermission()

        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let modelContainer = ModelContainer.shared
        let context = modelContainer.mainContext as! ModelContext

        Task {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                NotificationStore.shared.refreshNotifications(modelContext: context) {
                    continuation.resume()
                }
            }
            completionHandler(.newData)
        }
    }

    func registerBackgroundTasks() {
        print("Registering background tasks")

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.taskape.refreshNotifications", using: nil) { task in
            print("Background task triggered: \(task.identifier)")
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.taskape.refreshNotifications")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Successfully scheduled background refresh")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        let modelContainer = ModelContainer.shared
        let context = modelContainer.mainContext as! ModelContext

        let refreshTask = Task {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                NotificationStore.shared.refreshNotifications(modelContext: context) {
                    continuation.resume()
                }
            }
        }

        task.expirationHandler = {
            refreshTask.cancel()
        }

        Task {
            _ = await refreshTask.value
            task.setTaskCompleted(success: true)
        }
    }

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier

        if identifier.hasPrefix("taskape.notification.") {}

        completionHandler()
    }
}

@main
struct taskapeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(ModelContainer.shared)
                .environmentObject(appState)
                .onAppear {
                    let memoryCapacity = 50 * 1024 * 1024 * 2
                    let diskCapacity = 200 * 1024 * 1024 * 5

                    URLCache.shared.memoryCapacity = memoryCapacity
                    URLCache.shared.diskCapacity = diskCapacity
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didEnterBackgroundNotification)
                ) { _ in

                    appDelegate.scheduleBackgroundRefresh()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification)
                ) { _ in

                    UIApplication.shared.applicationIconBadgeNumber =
                        NotificationStore.shared.unreadCount
                }
        }
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(
                for: taskapeUser.self, taskapeTask.self, taskapeEvent.self,
                taskapeGroup.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
