//
//  serverPostRequests.swift
//  taskape
//
//  Created by shevlfs on 2/23/25.
//

import Alamofire
import Foundation
import SwiftData

struct BatchTaskSubmissionRequest: Codable {
    let tasks: [TaskSubmission]
    let token: String
}

struct TaskSubmission: Codable {
    let user_id: String
    let name: String
    let description: String
    let deadline: String?
    let author: String
    let group: String?
    let group_id: String?
    let assigned_to: [String]
    let difficulty: String
    let custom_hours: Int?
    let privacy_level: String
    let privacy_except_ids: [String]
}

struct TaskResponse: Codable {
    let id: String
    let user_id: String
    let name: String
    let description: String
    let created_at: String
    let deadline: String?
    let author: String
    let group: String?
    let group_id: String?
    let assigned_to: [String]
    let task_difficulty: String
    let custom_hours: Int?
    let is_completed: Bool
    let proof_url: String?
    let privacy_level: String
    let privacy_except_ids: [String]
}

struct BatchTaskSubmissionResponse: Codable {
    let success: Bool
    let task_ids: [String]
    let message: String?
}

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
            "http://localhost:8080/submitTasksBatch",
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

struct GetTasksResponse: Codable {
    let success: Bool
    let tasks: [TaskResponse]
    let message: String?
}

func fetchUserTasks(userId: String) async -> [TaskResponse]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    do {
        let result = await AF.request(
            "http://localhost:8080/users/\(userId)/tasks",
            method: .get,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(GetTasksResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return response.tasks
            } else {
                print(
                    "Failed to fetch tasks: \(response.message ?? "Unknown error")"
                )
                return nil
            }
        case .failure(let error):
            print("Failed to fetch tasks: \(error.localizedDescription)")
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
        assignedToTask: taskResponse.assigned_to,
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

func syncUserTasks(userId: String, modelContext: ModelContext) async {
    guard let remoteTasks = await fetchUserTasks(userId: userId) else {
        print("Failed to fetch remote tasks")
        return
    }

    let localTasks = remoteTasks.map { convertToLocalTask($0) }

    let descriptor = FetchDescriptor<taskapeTask>(
        predicate: #Predicate<taskapeTask> { task in
            task.user_id == userId
        }
    )

    do {
        let existingTasks = try modelContext.fetch(descriptor)

        let existingTaskMap = Dictionary(
            uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })

        for remoteTask in localTasks {
            if let existingTask = existingTaskMap[remoteTask.id] {
                existingTask.name = remoteTask.name
                existingTask.taskDescription = remoteTask.taskDescription
                existingTask.deadline = remoteTask.deadline
                existingTask.completion = remoteTask.completion
                existingTask.privacy = remoteTask.privacy
                existingTask.assignedToTask = remoteTask.assignedToTask
                existingTask.task_difficulty = remoteTask.task_difficulty
                existingTask.custom_hours = remoteTask.custom_hours
            } else {
                modelContext.insert(remoteTask)
            }
        }

        try modelContext.save()

    } catch {
        print("Failed to sync tasks: \(error)")
    }
}
