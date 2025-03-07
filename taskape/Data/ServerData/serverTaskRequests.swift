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

        return TaskSubmission(
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
            privacy_level: task.privacy.level.rawValue,
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
    switch taskResponse.privacy_level {
    case "everyone":
        privacyLevel = .everyone
    case "friends-only":
        privacyLevel = .friendsOnly
    case "group":
        privacyLevel = .group
    case "noone":
        privacyLevel = .noone
    default:
        privacyLevel = .everyone
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
        privacy: taskResponse.privacy_level,
        group: taskResponse.group,
        group_id: taskResponse.group_id,
        assignedToTask: taskResponse.assigned_to ?? [],
        task_difficulty: difficulty,
        custom_hours: taskResponse.custom_hours,
        mentioned_in_event: false
    )

    task.createdAt = createdAt

    task.deadline = deadline

    task.completion = completionStatus

    task.privacy = privacySettings

    return task
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

    let request = TaskUpdateRequest(
        id: task.id,
        user_id: task.user_id,
        name: task.name,
        description: task.taskDescription,
        deadline: deadlineString,
        assignedTo: task.assignedToTask,
        difficulty: task.task_difficulty.rawValue,
        customHours: task.custom_hours,
        isCompleted: task.completion.isCompleted,
        proofURL: task.completion.proofURL,
        privacyLevel: task.privacy.level.rawValue,
        privacyExceptIDs: task.privacy.exceptIDs,
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
func syncUserTasks(userId: String, remoteTasks: [taskapeTask], modelContext: ModelContext) {
    let descriptor = FetchDescriptor<taskapeTask>(
        predicate: #Predicate<taskapeTask> { task in
            task.user_id == userId
        }
    )

    do {
        let existingTasks = try modelContext.fetch(descriptor)
        let existingTaskMap = Dictionary(
            uniqueKeysWithValues: existingTasks.map { ($0.id, $0) }
        )

        for remoteTask in remoteTasks {
            if let existingTask = existingTaskMap[remoteTask.id] {
                // Update existing task
                existingTask.name = remoteTask.name
                existingTask.taskDescription = remoteTask.taskDescription
                existingTask.deadline = remoteTask.deadline
                existingTask.completion = remoteTask.completion
                existingTask.privacy = remoteTask.privacy
                existingTask.assignedToTask = remoteTask.assignedToTask
                existingTask.task_difficulty = remoteTask.task_difficulty
                existingTask.custom_hours = remoteTask.custom_hours
            } else {
                // Insert new task
                modelContext.insert(remoteTask)
            }
        }

        try modelContext.save()
    } catch {
        print("Failed to sync tasks: \(error)")
    }
}
