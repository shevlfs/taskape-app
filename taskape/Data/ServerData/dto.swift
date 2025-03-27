//
//  dto.swift
//  taskape
//
//  Created by shevlfs on 2/14/25.
//

import Foundation

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
    let friends: [Friend]?
    let incoming_requests: [FriendRequest]?
    let outgoing_requests: [FriendRequest]?
    let error: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        success = try container.decode(Bool.self, forKey: .success)
        id = try container.decode(String.self, forKey: .id)
        handle = try container.decode(String.self, forKey: .handle)
        bio = try container.decode(String.self, forKey: .bio)
        profile_picture = try container.decode(
            String.self, forKey: .profile_picture)
        color = try container.decode(String.self, forKey: .color)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        friends =
            try container.decodeIfPresent([Friend].self, forKey: .friends) ?? []
        incoming_requests =
            try container.decodeIfPresent(
                [FriendRequest].self, forKey: .incoming_requests) ?? []
        outgoing_requests =
            try container.decodeIfPresent(
                [FriendRequest].self, forKey: .outgoing_requests) ?? []
    }
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
    let flag_status: Bool
    let flag_color: String?
    let flag_name: String?
    let display_order: Int

    // Decoder implementation...
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

        // New fields
        flag_status =
            try container.decodeIfPresent(Bool.self, forKey: .flag_status)
            ?? false
        flag_color = try container.decodeIfPresent(
            String.self, forKey: .flag_color)
        flag_name = try container.decodeIfPresent(
            String.self, forKey: .flag_name)
        display_order =
            try container.decodeIfPresent(Int.self, forKey: .display_order) ?? 0
    }

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
        case flag_status = "flag_status"
        case flag_color = "flag_color"
        case flag_name = "flag_name"
        case display_order = "display_order"
    }
}

struct TaskOrderUpdateRequest: Codable {
    let userID: String
    let tasks: [TaskOrderItem]
    let token: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case tasks
        case token
    }
}

struct TaskOrderItem: Codable {
    let taskID: String
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case displayOrder = "display_order"
    }
}

struct TaskOrderUpdateResponse: Codable {
    let success: Bool
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
    let flag_status: Bool
    let flag_color: String?
    let flag_name: String?
    let display_order: Int
    let token: String
}

struct Friend: Codable {
    let id: String
    let handle: String
    let profile_picture: String
    let color: String
}

struct FriendRequest: Codable {
    let id: String
    let sender_id: String
    let sender_handle: String
    let receiver_id: String
    let status: String
    let created_at: String

    var isIncoming: Bool {
        return UserDefaults.standard.string(forKey: "user_id") == receiver_id
    }
}

struct SearchUsersRequest: Codable {
    let query: String
    let limit: Int
    let token: String
}

struct SearchUsersResponse: Codable {
    let success: Bool
    let users: [UserSearchResult]
    let message: String?
}

struct UserSearchResult: Codable {
    let id: String
    let handle: String
    let profile_picture: String
    let color: String
}

struct SendFriendRequestRequest: Codable {
    let sender_id: String
    let receiver_id: String
    let token: String
}

struct SendFriendRequestResponse: Codable {
    let success: Bool
    let request_id: String?
    let message: String?
}

struct RespondToFriendRequestRequest: Codable {
    let request_id: String
    let user_id: String
    let response: String  // "accept" or "reject"
    let token: String
}

struct RespondToFriendRequestResponse: Codable {
    let success: Bool
    let message: String?
}

struct GetTaskResponse: Codable {
    let success: Bool
    let task: TaskResponse
    let message: String?
}

// Define DTOs to match the Go server types

struct EventResponse: Codable {
    let id: String
    let user_id: String
    let target_user_id: String
    let type: String
    let size: String
    let created_at: String
    let expires_at: String?
    let task_ids: [String]
    let streak_days: Int
    let likes_count: Int
    let comments_count: Int
    let liked_by_user_ids: [String]?
}

struct GetEventsResponse: Codable {
    let success: Bool
    let events: [EventResponse]
    let message: String?
}

struct LikeEventRequest: Codable {
    let user_id: String
    let token: String
}

struct LikeEventResponse: Codable {
    let success: Bool
    let likes_count: Int
    let message: String?
}

struct EventCommentResponse: Codable {
    let id: String
    let event_id: String
    let user_id: String
    let content: String
    let created_at: String
    let is_edited: Bool
    let edited_at: String?
}

struct AddEventCommentRequest: Codable {
    let user_id: String
    let content: String
    let token: String
}

struct GetEventCommentsResponse: Codable {
    let success: Bool
    let comments: [EventCommentResponse]
    let total_count: Int
    let message: String?
}

struct ConfirmTaskCompletionRequest: Codable {
    let task_id: String
    let confirmer_id: String
    let is_confirmed: Bool
    let token: String
}

struct ConfirmTaskCompletionResponse: Codable {
    let success: Bool
    let message: String?
}

