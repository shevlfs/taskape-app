import Alamofire
import Combine
import Foundation
import SwiftData
import SwiftDotenv

func fetchUser(userId: String) async -> taskapeUser? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(UserResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                let user = taskapeUser(
                    id: String(response.id),
                    handle: response.handle,
                    bio: response.bio,
                    profileImage: response.profile_picture,
                    profileColor: response.color
                )
                print("user handle:", user.handle)

                // Store friend data
                if let friends = response.friends, !friends.isEmpty {
                    // You might want to create a method to store friends in your data model
                    // For now, we'll leave this commented as we need to update the taskapeUser model
                    // storeFriends(user: user, friends: friends)
                }

                return user
            } else {
                print(
                    "Failed to fetch user: \(response.error ?? "Unknown error")"
                )
                return nil
            }
        case .failure(let error):
            print("Failed to fetch user: \(error.localizedDescription)")
            return nil
        }
    }
}

// Insert function - handles the SwiftData operations only
func insertUser(user: taskapeUser, context: ModelContext) {
    let userID = user.id  // Capture the user id in a local constant
    print("Inserting user with ID: \(userID), handle: \(user.handle)")

    // First, check if there's already a user with this ID
    let descriptor = FetchDescriptor<taskapeUser>(
        predicate: #Predicate<taskapeUser> { $0.id == userID }
    )

    do {
        // We'll make sure this user is the only one
        let allUsersDescriptor = FetchDescriptor<taskapeUser>()
        let allUsers = try context.fetch(allUsersDescriptor)

        if !allUsers.isEmpty {
            print(
                "Found \(allUsers.count) existing users - will ensure only the current user exists"
            )

            // Delete all users except the one we're adding (if it exists)
            for existingUser in allUsers {
                if existingUser.id != userID {
                    context.delete(existingUser)
                }
            }
        }

        // Now look specifically for our user
        let existingUsers = try context.fetch(descriptor)

        if existingUsers.isEmpty {
            print("Inserting new user with ID: \(userID)")
            context.insert(user)
        } else {
            print("User with ID: \(userID) already exists, updating properties")
            let existingUser = existingUsers.first!
            // Update the existing user's properties
            existingUser.handle = user.handle
            existingUser.bio = user.bio
            existingUser.profileImageURL = user.profileImageURL
            existingUser.profileColor = user.profileColor
            // Don't modify the tasks array to preserve existing relationships
        }

        try context.save()
        print("Saved changes to context after user operation")
    } catch {
        print("Failed to fetch or insert user: \(error)")
    }
}

// Fetch function - performs the network request for tasks
func fetchTasks(userId: String) async -> [taskapeTask]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    // Get the current user ID for the requester_id
    let requesterId = UserManager.shared.currentUserId

    print("Fetching tasks for user ID: \(userId), requester ID: \(requesterId)")

    do {
        // Include the requester_id as a query parameter
        let url =
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/tasks?requester_id=\(requesterId)"

        let result = await AF.request(
            url,
            method: .get,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(GetTasksResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                let localTasks = response.tasks.map { convertToLocalTask($0) }
                return localTasks
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
