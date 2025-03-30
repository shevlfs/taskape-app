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
    private let appGroupIdentifier = "group.com.shevlfs.taskape" // Make sure this matches your app group identifier

    private init() {}

    // In WidgetDataManager.swift
    func saveTasks(_ tasks: [taskapeTask]) {
        print("WidgetDataManager: Attempting to save \(tasks.count) tasks")

        // Deduplicate tasks based on ID (keeping only the latest version of each task)
        var uniqueTasks = [String: taskapeTask]()
        for task in tasks {
            uniqueTasks[task.id] = task
        }

        let deduplicatedTasks = Array(uniqueTasks.values)
        print("WidgetDataManager: After deduplication, saving \(deduplicatedTasks.count) tasks")

        let widgetTasks = deduplicatedTasks.map { task -> WidgetTaskModel in
            return WidgetTaskModel(
                id: task.id,
                name: task.name,
                isCompleted: task.completion.isCompleted,
                flagColor: task.flagColor,
                flagName: task.flagName
            )
        }

        do {
            let data = try JSONEncoder().encode(widgetTasks)
            let userDefaults = UserDefaults(suiteName: appGroupIdentifier)
            userDefaults?.set(data, forKey: "taskape_widget_tasks")
            let success = userDefaults?.synchronize() ?? false

            // Add verification step
            if let savedData = userDefaults?.data(forKey: "taskape_widget_tasks") {
                // Verification succeeded
            } else {
                print("WidgetDataManager: ⚠️ Verification FAILED - data not found after save")
            }

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("WidgetDataManager: Failed to encode tasks: \(error)")
        }
    }

    // Load tasks from shared container (used by widget)
    func loadTasks() -> [WidgetTaskModel] {
        let userDefaults = UserDefaults(suiteName: appGroupIdentifier)

        guard let data = userDefaults?.data(forKey: "taskape_widget_tasks")
        else {
            return []
        }

        do {
            let widgetTasks = try JSONDecoder().decode(
                [WidgetTaskModel].self, from: data)
            print("Widget: Successfully loaded \(widgetTasks.count) tasks")
            return widgetTasks
        } catch {
            print("Widget: Failed to decode tasks: \(error)")
            return []
        }
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
