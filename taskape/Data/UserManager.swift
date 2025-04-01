import Foundation
import SwiftData
import SwiftUI
import WidgetKit

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUserId: String =
        UserDefaults.standard.string(forKey: "user_id") ?? ""


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


    func fetchCurrentUserTasks() async -> [taskapeTask]? {
        guard !currentUserId.isEmpty else { return nil }
        return await fetchTasks(userId: currentUserId)
    }


    func isCurrentUser(userId: String) -> Bool {
        return userId == currentUserId
    }


    func setCurrentUser(userId: String) {
        currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "user_id")
    }
}

extension UserManager {

    func syncTasksWithWidget(context: ModelContext) {
        if let user = getCurrentUser(context: context) {

            let sortedTasks = user.tasks.sorted { $0.displayOrder > $1.displayOrder }
            WidgetDataManager.shared.saveTasks(sortedTasks)
        }
    }


    func syncCurrentUserTasksWithWidget(tasks: [taskapeTask]) {

        let sortedTasks = tasks.sorted { $0.displayOrder > $1.displayOrder }
        WidgetDataManager.shared.saveTasks(sortedTasks)
    }
}


extension taskapeTask {

    func syncWithWidget() {

        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            Task {
                if let tasks = await fetchTasks(userId: userId) {
                    UserManager.shared.syncCurrentUserTasksWithWidget(tasks: tasks)
                }
            }
        }
    }
}
