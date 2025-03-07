// Fixed Fetchers.swift

import Alamofire
import Combine
import Foundation
import SwiftData
import SwiftDotenv

// Fetch function - performs the network request only
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
                return user
            } else {
                print("Failed to fetch user: \(response.error ?? "Unknown error")")
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
    print("Attempting to insert/update user with ID: \(userID), handle: \(user.handle)")

    let descriptor = FetchDescriptor<taskapeUser>(
        predicate: #Predicate<taskapeUser> { $0.id == userID }
    )

    do {
        let existingUsers = try context.fetch(descriptor)
        print("Found \(existingUsers.count) existing users with ID: \(userID)")

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

    print("USER ID", userId)

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/tasks",
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
                print("Failed to fetch tasks: \(response.message ?? "Unknown error")")
                return nil
            }
        case .failure(let error):
            print("Failed to fetch tasks: \(error.localizedDescription)")
            return nil
        }
    }
}

// Insert function - handles the SwiftData operations for tasks
func insertTasks(tasks: [taskapeTask], modelContext: ModelContext) {
    print("Attempting to insert/update \(tasks.count) tasks")

    do {
        // First, make sure we have tasks to process
        if tasks.isEmpty {
            print("No tasks to process")
            return
        }

        // Get the user ID from the first task
        let userID = tasks.first!.user_id
        let userDescriptor = FetchDescriptor<taskapeUser>(
            predicate: #Predicate<taskapeUser> { user in
                user.id == userID
            }
        )

        let users = try modelContext.fetch(userDescriptor)
        guard let user = users.first else {
            print("ERROR: Could not find user with ID: \(userID) to associate tasks with!")
            return
        }

        print("Found user: \(user.handle) with ID: \(userID) for task association")

        // Process each task
        for remoteTask in tasks {
            let taskID = remoteTask.id
            print("Processing task with ID: \(taskID), name: \(remoteTask.name)")

            let descriptor = FetchDescriptor<taskapeTask>(
                predicate: #Predicate<taskapeTask> { task in
                    task.id == taskID
                }
            )

            let existingTasks = try modelContext.fetch(descriptor)
            print("Found \(existingTasks.count) existing tasks with ID: \(taskID)")

            if let existingTask = existingTasks.first {
                print("Updating existing task with ID: \(taskID)")
                existingTask.name = remoteTask.name
                existingTask.taskDescription = remoteTask.taskDescription
                existingTask.deadline = remoteTask.deadline
                existingTask.completion = remoteTask.completion
                existingTask.privacy = remoteTask.privacy
                existingTask.assignedToTask = remoteTask.assignedToTask
                existingTask.task_difficulty = remoteTask.task_difficulty
                existingTask.custom_hours = remoteTask.custom_hours
            } else {
                print("Inserting new task with ID: \(taskID)")
                modelContext.insert(remoteTask)
                if !user.tasks.contains(where: { $0.id == remoteTask.id }) {
                    print("Associating task \(taskID) with user \(user.handle)")
                    user.tasks.append(remoteTask)
                }
            }
        }

        try modelContext.save()
        print("Saved changes to context after processing \(tasks.count) tasks")
    } catch {
        print("Failed to sync tasks: \(error)")
    }
}
