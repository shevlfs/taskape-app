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

    enum CodingKeys: String, CodingKey {
        case id, name, description, author, group
        case user_id = "user_id"
        case created_at = "created_at"
        case deadline
        case group_id = "group_id"
        case assigned_to = "assigned_to"
        case task_difficulty = "task_difficulty"
        case custom_hours = "custom_hours"
        case is_completed = "is_completed"
        case proof_url = "proof_url"
        case privacy_level = "privacy_level"
        case privacy_except_ids = "privacy_except_ids"
    }

    // Add an initializer to handle null values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        user_id = try container.decode(String.self, forKey: .user_id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        created_at = try container.decode(String.self, forKey: .created_at)
        deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        author = try container.decode(String.self, forKey: .author)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        group_id = try container.decodeIfPresent(String.self, forKey: .group_id)

        // Handle possibly null array
        if let assignedTo = try? container.decodeIfPresent(
            [String].self, forKey: .assigned_to)
        {
            assigned_to = assignedTo
        } else {
            assigned_to = []
        }

        task_difficulty = try container.decode(
            String.self, forKey: .task_difficulty)
        custom_hours = try container.decodeIfPresent(
            Int.self, forKey: .custom_hours)
        is_completed = try container.decode(Bool.self, forKey: .is_completed)
        proof_url = try container.decodeIfPresent(
            String.self, forKey: .proof_url)
        privacy_level = try container.decode(
            String.self, forKey: .privacy_level)

        // Handle possibly null array
        if let privacyExceptIds = try? container.decodeIfPresent(
            [String].self, forKey: .privacy_except_ids)
        {
            privacy_except_ids = privacyExceptIds
        } else {
            privacy_except_ids = []
        }
    }
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
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/tasks",
            method: .get,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(GetTasksResponse.self)
        .response

        // Log raw response for debugging
        if let data = result.data,
            let jsonString = String(data: data, encoding: .utf8)
        {
            print("Raw JSON response: \(jsonString)")
        }

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

            // Try to decode the response in a more lenient way for debugging
            if let data = result.data {
                do {
                    let json = try JSONSerialization.jsonObject(
                        with: data, options: [])
                    print("Raw response content: \(json)")
                } catch {
                    print("Could not parse response as JSON: \(error)")
                }
            }

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
