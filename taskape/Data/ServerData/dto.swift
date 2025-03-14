//
//  dto.swift
//  taskape
//
//  Created by shevlfs on 2/14/25.
//

struct VerificationResponse: Codable {
    let authToken: String
    let refreshToken: String
    let profileExists: Bool
    let userId: Int64
}

struct TokenRefreshResponse: Codable {
    let authToken: String
    let refreshToken: String
}

struct UserResponse: Codable {
    let success: Bool
    let id: String
    let handle: String
    let bio: String
    let profile_picture: String
    let color: String
    let error: String?
}

struct GetTasksResponse: Codable {
    let success: Bool
    let tasks: [TaskResponse]
    let message: String?
}

struct BatchTaskSubmissionResponse: Codable {
    let success: Bool
    let task_ids: [String]
    let message: String?
}

struct TaskUpdateRequest: Codable {
    let id: String
    let user_id: String
    let name: String
    let description: String
    let deadline: String?
    let assigned_to: [String]
    let difficulty: String
    let customHours: Int?
    let is_completed: Bool
    let proof_url: String?
    let privacy_level: String
    let privacy_except_ids: [String]
    let token: String
}

struct TaskUpdateResponse: Codable {
    let success: Bool
    let message: String?
}

struct CheckHandleAvailabilityResponse: Codable {
    let available: Bool
    let message: String?
}

struct RegisterNewProfileRequest: Codable {
    let handle: String
    let bio: String
    let color: String
    let profile_picture: String
    let phone: String
    let token: String
}

struct RegisterNewProfileResponse: Codable {
    let success: Bool
    let id: Int
}

struct TaskSubmissionResponse: Codable {
    let success: Bool
    let taskId: Int
}

struct BatchTaskSubmissionRequest: Codable {
    let tasks: [TaskSubmission]
    let token: String
}

struct TaskSubmission: Codable {
    let id: String
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
