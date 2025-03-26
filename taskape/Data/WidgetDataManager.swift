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

    // In WidgetDataManager.swift
    func saveTasks(_ tasks: [taskapeTask]) {
        print("WidgetDataManager: Attempting to save \(tasks.count) tasks")

        let widgetTasks = tasks.map { task -> WidgetTaskModel in
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
            print("WidgetDataManager: Writing to UserDefaults group: \(appGroupIdentifier ?? "nil")")
            userDefaults?.set(data, forKey: "taskape_widget_tasks")
            let success = userDefaults?.synchronize() ?? false
            print("WidgetDataManager: Save and synchronize \(success ? "succeeded" : "failed")")

            // Add verification step
            if let savedData = userDefaults?.data(forKey: "taskape_widget_tasks") {
                print("WidgetDataManager: Verified data exists in UserDefaults (\(savedData.count) bytes)")
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
        print(
            "Widget attempting to load data from group: \(appGroupIdentifier)")

        guard let data = userDefaults?.data(forKey: "taskape_widget_tasks")
        else {
            print("Widget: No data found for key 'taskape_widget_tasks'")
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
