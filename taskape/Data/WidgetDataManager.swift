//
//  WidgetTaskModel.swift
//  taskape
//
//  Created by shevlfs on 3/26/25.
//

import Foundation
import SwiftUI
import WidgetKit

// Shared app group identifier - must match what's in your entitlements
let appGroupIdentifier = "group.com.taskape.shared"

// Model for tasks in widget - simple version of taskapeTask
struct WidgetTaskModel: Identifiable, Codable {
    let id: String
    let name: String
    let isCompleted: Bool
    let flagColor: String?
    let flagName: String?
}

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private init() {}

    // Save tasks to shared container for widget access
    func saveTasks(_ tasks: [taskapeTask]) {
        let widgetTasks = tasks.map { task -> WidgetTaskModel in
            return WidgetTaskModel(
                id: task.id,
                name: task.name,
                isCompleted: task.completion.isCompleted,
                flagColor: task.flagColor,
                flagName: task.flagName
            )
        }

        if let data = try? JSONEncoder().encode(widgetTasks) {
            let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
            userDefaults?.set(data, forKey: "taskape_widget_tasks")
            userDefaults?.synchronize()

            // Refresh widget
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // Load tasks from shared container (used by widget)
    func loadTasks() -> [WidgetTaskModel] {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        guard let data = userDefaults?.data(forKey: "taskape_widget_tasks"),
            let widgetTasks = try? JSONDecoder().decode(
                [WidgetTaskModel].self, from: data)
        else {
            return []
        }

        return widgetTasks
    }
}

class TaskNotifier {
    static func notifyTasksUpdated() {
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskapeTasksUpdated"),
            object: nil
        )
    }
}
