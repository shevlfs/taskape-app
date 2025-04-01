






import Foundation
import SwiftUI
import WidgetKit




struct WidgetTaskModel: Identifiable, Codable {
    let id: String
    let name: String
    let isCompleted: Bool
    let flagColor: String?
    let flagName: String?
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let appGroupIdentifier = "group.com.shevlfs.taskape"

    private init() {}


    func saveTasks(_ tasks: [taskapeTask]) {
        print("WidgetDataManager: [STUB] Would save \(tasks.count) tasks")

    }


    func loadTasks() -> [WidgetTaskModel] {
        print("WidgetDataManager: [STUB] Would load tasks")
        return []
    }
}

class TaskNotifier {
    static func notifyTasksUpdated() {
        print("TaskNotifier: [STUB] Would notify tasks updated")

    }
}
