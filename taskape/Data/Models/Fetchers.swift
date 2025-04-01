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


                if let friends = response.friends, !friends.isEmpty {



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


func insertUser(user: taskapeUser, context: ModelContext) {
    let userID = user.id 
    print("Inserting user with ID: \(userID), handle: \(user.handle)")


    let descriptor = FetchDescriptor<taskapeUser>(
        predicate: #Predicate<taskapeUser> { $0.id == userID }
    )

    do {

        let allUsersDescriptor = FetchDescriptor<taskapeUser>()
        let allUsers = try context.fetch(allUsersDescriptor)

        if !allUsers.isEmpty {
            print(
                "Found \(allUsers.count) existing users - will ensure only the current user exists"
            )


            for existingUser in allUsers {
                if existingUser.id != userID {
                    context.delete(existingUser)
                }
            }
        }


        let existingUsers = try context.fetch(descriptor)

        if existingUsers.isEmpty {
            print("Inserting new user with ID: \(userID)")
            context.insert(user)
        } else {
            print("User with ID: \(userID) already exists, updating properties")
            let existingUser = existingUsers.first!

            existingUser.handle = user.handle
            existingUser.bio = user.bio
            existingUser.profileImageURL = user.profileImageURL
            existingUser.profileColor = user.profileColor

        }

        try context.save()
        print("Saved changes to context after user operation")
    } catch {
        print("Failed to fetch or insert user: \(error)")
    }
}


func fetchTasks(userId: String) async -> [taskapeTask]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }


    let requesterId = UserManager.shared.currentUserId

    print("Fetching tasks for user ID: \(userId), requester ID: \(requesterId)")

    do {

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

    var confirmedAt: Date? = nil
    if let confirmedAtString = taskResponse.confirmed_at {
        confirmedAt = dateFormatter.date(from: confirmedAtString)
    }

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
        isCompleted: taskResponse.is_completed,
        proofURL: taskResponse.proof_url,
        requiresConfirmation: taskResponse.requires_confirmation,
        isConfirmed: taskResponse.is_confirmed,
        confirmedBy: taskResponse.confirmation_user_id,
        confirmedAt: confirmedAt
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
        displayOrder: taskResponse.display_order,
        proofNeeded: taskResponse.requires_confirmation
    )

    task.createdAt = createdAt
    task.deadline = deadline
    task.completion = completionStatus
    task.privacy = privacySettings

    return task
}
