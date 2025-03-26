import Foundation
import SwiftData
import SwiftUI
import WidgetKit

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUserId: String =
        UserDefaults.standard.string(forKey: "user_id") ?? ""

    // Fetch the current user from the ModelContext using the ID
    func getCurrentUser(context: ModelContext) -> taskapeUser? {
        guard !currentUserId.isEmpty else { return nil }

        let predicate = #Predicate<taskapeUser> {
            user in user.id == currentUserId
        }

        let descriptor = FetchDescriptor<taskapeUser>(predicate: predicate)

        do {
            let users = try context.fetch(descriptor)
            return users.first
        } catch {
            print("Error fetching current user: \(error)")
            return nil
        }
    }

    // Fetch tasks for the current user
    func getCurrentUserTasks(context: ModelContext) -> [taskapeTask] {
        guard !currentUserId.isEmpty else { return [] }

        let predicate = #Predicate<taskapeTask> {
            task in task.user_id == currentUserId
        }

        let descriptor = FetchDescriptor<taskapeTask>(predicate: predicate)

        do {
            let tasks = try context.fetch(descriptor)
            return tasks
        } catch {
            print("Error fetching tasks for current user: \(error)")
            return []
        }
    }

    // Fetch tasks from server and return them - to be called from main thread context
    func fetchCurrentUserTasks() async -> [taskapeTask]? {
        guard !currentUserId.isEmpty else { return nil }
        return await fetchTasks(userId: currentUserId)
    }

    // Check if a user is the current user
    func isCurrentUser(userId: String) -> Bool {
        return userId == currentUserId
    }

    // Update the current user ID (e.g., after login)
    func setCurrentUser(userId: String) {
        currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "user_id")
    }
}

extension UserManager {
    // Sync current user tasks with widget
    func syncTasksWithWidget(context: ModelContext) {
        if let user = getCurrentUser(context: context) {
            // Sort tasks by display order before saving
            let sortedTasks = user.tasks.sorted { $0.displayOrder > $1.displayOrder }
            WidgetDataManager.shared.saveTasks(sortedTasks)
        }
    }

    // Call this after tasks are fetched or updated
    func syncCurrentUserTasksWithWidget(tasks: [taskapeTask]) {
        // Sort tasks by display order before saving
        let sortedTasks = tasks.sorted { $0.displayOrder > $1.displayOrder }
        WidgetDataManager.shared.saveTasks(sortedTasks)
    }
}

// Extension to sync tasks with widget when they change
extension taskapeTask {
    // Call this when a task is updated
    func syncWithWidget() {
        // Get all tasks for current user and sync
        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            Task {
                if let tasks = await fetchTasks(userId: userId) {
                    UserManager.shared.syncCurrentUserTasksWithWidget(tasks: tasks)
                }
            }
        }
    }
}
