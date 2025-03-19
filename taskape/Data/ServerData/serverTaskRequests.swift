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
            author: task.author,
            group: task.group,
            group_id: task.group_id,
            assigned_to: task.assignedToTask,
            difficulty: task.task_difficulty.rawValue,
            custom_hours: task.custom_hours,
            privacy_level: privacyLevelString,  // Use the converted string value
            privacy_except_ids: task.privacy.exceptIDs
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

func convertToLocalTask(_ taskResponse: TaskResponse) -> taskapeTask {
    let dateFormatter = ISO8601DateFormatter()

    var deadline: Date? = nil
    if let deadlineString = taskResponse.deadline {
        deadline = dateFormatter.date(from: deadlineString)
    }

    let createdAt = dateFormatter.date(from: taskResponse.created_at) ?? Date()

    let privacyLevel: PrivacySettings.PrivacyLevel
    if taskResponse.privacy_level.isEmpty {
        privacyLevel = .everyone
    } else {
        switch taskResponse.privacy_level {
        case "everyone":
            privacyLevel = .everyone
        case "friends-only":
            privacyLevel = .friendsOnly
        case "group":
            privacyLevel = .group
        case "noone":
            privacyLevel = .noone
        case "except":
            privacyLevel = .except
        default:
            privacyLevel = .everyone
        }
    }

    let privacySettings = PrivacySettings(
        level: privacyLevel, exceptIDs: taskResponse.privacy_except_ids)

    let completionStatus = CompletionStatus(
        isCompleted: taskResponse.is_completed, proofURL: taskResponse.proof_url
    )

    let difficulty: TaskDifficulty
    switch taskResponse.task_difficulty {
    case "small":
        difficulty = .small
    case "medium":
        difficulty = .medium
    case "large":
        difficulty = .large
    case "custom":
        difficulty = .custom
    default:
        difficulty = .medium
    }

    
    let task = taskapeTask(
        id: taskResponse.id,
        user_id: taskResponse.user_id,
        name: taskResponse.name,
        taskDescription: taskResponse.description,
        author: taskResponse.author,
        privacy: privacySettings,
        group: taskResponse.group,
        group_id: taskResponse.group_id,
        assignedToTask: taskResponse.assigned_to ?? [],
        task_difficulty: difficulty,
        custom_hours: taskResponse.custom_hours,
        mentioned_in_event: false,
        flagStatus: taskResponse.flag_status,
        flagColor: taskResponse.flag_color,
        flagName: taskResponse.flag_name,
        displayOrder: taskResponse.display_order
    )

    task.createdAt = createdAt
    task.deadline = deadline
    task.completion = completionStatus
    task.privacy = privacySettings

    return task
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
    } else {
        print("Failed to sync task with server")
    }
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

        // Create efficient maps for lookup
        let remoteTaskMap = Dictionary(
            uniqueKeysWithValues: remoteTasks.map { ($0.id, $0) })
        let existingTaskMap = Dictionary(
            uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })

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
        for remoteTask in remoteTasks {
            if existingTaskMap[remoteTask.id] == nil {
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
        try modelContext.save()
        print("Successfully synced tasks for user \(userId)")

    } catch {
        print("Failed to sync tasks: \(error)")
    }
}
