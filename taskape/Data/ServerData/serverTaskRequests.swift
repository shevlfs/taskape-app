//
//  serverPostRequests.swift
//  taskape
//
//  Created by shevlfs on 2/23/25.
//

import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import WidgetKit

func submitTasksBatch(tasks: [taskapeTask]) async
    -> BatchTaskSubmissionResponse?
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    let taskSubmissions = tasks.map { task -> TaskSubmission in
        let deadlineString: String?
        if let deadline = task.deadline {
            let formatter = ISO8601DateFormatter()
            deadlineString = formatter.string(from: deadline)
        } else {
            deadlineString = nil
        }

        // Convert the privacy level enum to string
        let privacyLevelString: String
        switch task.privacy.level {
        case .everyone:
            privacyLevelString = "everyone"
        case .noone:
            privacyLevelString = "noone"
        case .friendsOnly:
            privacyLevelString = "friends-only"
        case .group:
            privacyLevelString = "group"
        case .except:
            privacyLevelString = "except"
        }

        return TaskSubmission(
            id: task.id,
            user_id: task.user_id,
            name: task.name,
            description: task.taskDescription,
            deadline: deadlineString,
            author: task.user_id,
            group: task.group,
            group_id: task.group_id,
            assigned_to: task.assignedToTask,
            difficulty: task.task_difficulty.rawValue,
            is_completed: task.completion.isCompleted,
            custom_hours: task.custom_hours,
            privacy_level: privacyLevelString,
            privacy_except_ids: task.privacy.exceptIDs,
            flag_status: task.flagStatus,
            flag_color: task.flagColor,
            flag_name: task.flagName,
            display_order: task.displayOrder,
            proof_needed: task.proofNeeded ?? false,
            proof_description: task.proofDescription,
            requires_confirmation: task.completion.requiresConfirmation,
            is_confirmed: task.completion.isConfirmed
        )
    }

    let requestPayload = BatchTaskSubmissionRequest(
        tasks: taskSubmissions,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/submitTasksBatch",
            method: .post,
            parameters: requestPayload,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(BatchTaskSubmissionResponse.self)
        .response

        switch result.result {
        case .success(let response):
            print("Successfully submitted \(response.task_ids.count) tasks")
            return response
        case .failure(let error):
            print("Failed to submit tasks batch: \(error.localizedDescription)")
            return nil
        }
    }
}

func updateTaskOrder(userID: String, taskOrders: [(taskID: String, order: Int)])
    async -> Bool
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return false
    }

    let items = taskOrders.map {
        TaskOrderItem(taskID: $0.taskID, displayOrder: $0.order)
    }

    let request = TaskOrderUpdateRequest(
        userID: userID,
        tasks: items,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/updateTaskOrder",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(TaskOrderUpdateResponse.self)
        .response

        switch result.result {
        case .success(let response):
            print("Task order update success: \(response.success)")
            return response.success
        case .failure(let error):
            print("Failed to update task order: \(error.localizedDescription)")
            return false
        }
    }
}

func updateTask(task: taskapeTask) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return false
    }

    let deadlineString: String?
    if let deadline = task.deadline {
        let formatter = ISO8601DateFormatter()
        deadlineString = formatter.string(from: deadline)
    } else {
        deadlineString = nil
    }

    // Convert the privacy level enum to string
    let privacyLevelString: String

    switch task.privacy.level {
    case .everyone:
        privacyLevelString = "everyone"
    case .noone:
        privacyLevelString = "noone"
    case .friendsOnly:
        privacyLevelString = "friends-only"
    case .group:
        privacyLevelString = "group"
    case .except:
        privacyLevelString = "except"
    @unknown default:
        privacyLevelString = "everyone"
    }

    let request = TaskUpdateRequest(
        id: task.id,
        user_id: task.user_id,
        name: task.name,
        description: task.taskDescription,
        deadline: deadlineString,
        assigned_to: task.assignedToTask,
        difficulty: task.task_difficulty.rawValue,
        customHours: task.custom_hours,
        is_completed: task.completion.isCompleted,
        proof_url: task.completion.proofURL,
        privacy_level: privacyLevelString,
        privacy_except_ids: task.privacy.exceptIDs,
        flag_status: task.flagStatus,
        flag_color: task.flagColor,
        flag_name: task.flagName,
        display_order: task.displayOrder,
        proof_needed: task.proofNeeded ?? false,
        proof_description: task.proofDescription,
        requires_confirmation: task.completion.requiresConfirmation,
        is_confirmed: task.completion.isConfirmed,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/updateTask",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(TaskUpdateResponse.self)
        .response

        switch result.result {
        case .success(let response):
            print("Task updated successfully: \(response.success)")
            return response.success
        case .failure(let error):
            print("Failed to update task: \(error.localizedDescription)")
            return false
        }
    }
}
func syncTaskChanges(task: taskapeTask) async {
    let success = await updateTask(task: task)

    if success {
        print("Task synced successfully with server")

        // Sync with widget after server update
        task.syncWithWidget()
        TaskNotifier.notifyTasksUpdated()

        // Post notification for widget update
        DispatchQueue.main.async {
            TaskNotifier.notifyTasksUpdated()
        }
    } else {
        print("Failed to sync task with server")
    }
}

func updateWidgetWithTasks(userId: String, modelContext: ModelContext) {
    //    // Get the current user's tasks
    //    let taskDescriptor = FetchDescriptor<taskapeTask>(
    //        predicate: #Predicate<taskapeTask> { task in
    //            task.user_id == userId && !task.completion.isCompleted
    //        }
    //    )
    //
    //    do {
    //        // Fetch incomplete tasks for the widget
    //        let tasks = try modelContext.fetch(taskDescriptor)
    //        print("Updating widget with \(tasks.count) tasks")
    //
    //        // Sort by display order
    //        let sortedTasks = tasks.sorted { $0.displayOrder > $1.displayOrder }
    //
    //        // Update widget data
    //        WidgetDataManager.shared.saveTasks(sortedTasks)
    //    } catch {
    //        print("Error fetching tasks for widget: \(error)")
    //    }
}

func syncUserTasks(
    userId: String, remoteTasks: [taskapeTask], modelContext: ModelContext
) {
    // First, fetch the user to properly associate tasks
    let userDescriptor = FetchDescriptor<taskapeUser>(
        predicate: #Predicate<taskapeUser> { user in
            user.id == userId
        }
    )

    // Fetch all existing tasks for the user
    let taskDescriptor = FetchDescriptor<taskapeTask>(
        predicate: #Predicate<taskapeTask> { task in
            task.user_id == userId
        }
    )

    do {
        // Get the user and existing tasks
        let users = try modelContext.fetch(userDescriptor)
        guard let user = users.first else {
            print("Error: No user found with ID \(userId) to sync tasks with")
            return
        }

        let existingTasks = try modelContext.fetch(taskDescriptor)
        print(
            "Syncing tasks: Found \(existingTasks.count) local tasks and \(remoteTasks.count) remote tasks"
        )

        // Create efficient maps for lookup - handling potential duplicates
        var remoteTaskMap = [String: taskapeTask]()
        for task in remoteTasks {
            // If duplicate exists, keep the most recent version (assuming last one is most recent)
            remoteTaskMap[task.id] = task
        }

        // Create map of existing tasks
        var existingTaskMap = [String: taskapeTask]()
        for task in existingTasks {
            existingTaskMap[task.id] = task
        }

        print("After deduplication: \(remoteTaskMap.count) unique remote tasks")

        // 1. Update existing tasks that are also in remote
        for existingTask in existingTasks {
            if let remoteTask = remoteTaskMap[existingTask.id] {
                // Update with remote values
                existingTask.name = remoteTask.name
                existingTask.taskDescription = remoteTask.taskDescription
                existingTask.deadline = remoteTask.deadline
                existingTask.completion = remoteTask.completion
                existingTask.privacy = remoteTask.privacy
                existingTask.assignedToTask = remoteTask.assignedToTask
                existingTask.task_difficulty = remoteTask.task_difficulty
                existingTask.custom_hours = remoteTask.custom_hours
                existingTask.flagStatus = remoteTask.flagStatus
                existingTask.flagColor = remoteTask.flagColor
                existingTask.flagName = remoteTask.flagName
                existingTask.displayOrder = remoteTask.displayOrder
                print(
                    "Updated existing task: \(existingTask.id) - \(existingTask.name)"
                )
            } else {
                // Only delete if the task has a valid server ID and wasn't just created locally
                // (assuming newly created tasks awaiting sync have a specific ID pattern or flag)
                if !existingTask.id.isEmpty && !existingTask.id.contains("temp")
                {
                    print(
                        "Deleting task not present on server: \(existingTask.id) - \(existingTask.name)"
                    )

                    // Also remove from user's tasks array
                    if let index = user.tasks.firstIndex(where: {
                        $0.id == existingTask.id
                    }) {
                        user.tasks.remove(at: index)
                    }

                    modelContext.delete(existingTask)
                }
            }
        }

        // 2. Insert new remote tasks that don't exist locally
        for (id, remoteTask) in remoteTaskMap {
            if existingTaskMap[id] == nil {
                // This is a new task from the server
                print(
                    "Inserting new remote task: \(remoteTask.id) - \(remoteTask.name)"
                )
                modelContext.insert(remoteTask)

                // Associate with user
                if !user.tasks.contains(where: { $0.id == remoteTask.id }) {
                    user.tasks.append(remoteTask)
                }
            }
        }

        // Save all changes at once
        // try modelContext.save()
        //  print("Successfully synced tasks for user \(userId)")

        //        UserManager.shared.syncCurrentUserTasksWithWidget(tasks: remoteTasks)
        //
        //        DispatchQueue.main.async {
        //            TaskNotifier.notifyTasksUpdated()
        //        }

        try modelContext.save()
        print("Successfully synced tasks for user \(userId)")

        // Update widget data
        updateWidgetWithTasks(userId: userId, modelContext: modelContext)

    } catch {
        print("Failed to sync tasks: \(error)")
    }
}

func fetchTask(taskId: String, requesterId: String) async -> taskapeTask? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/tasks/\(taskId)?requester_id=\(requesterId)",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(GetTaskResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return convertToLocalTask(response.task)
            } else {
                print(
                    "failed to fetch task: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case .failure(let error):
            print("failed to fetch task: \(error.localizedDescription)")
            return nil
        }
    }
}
