import Foundation
import SwiftData
import SwiftUI

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
