//
//  Fetchers.swift
//  taskape
//
//  Created by shevlfs on 3/4/25.
//

import Alamofire
import Combine
import Foundation
import SwiftData

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
            "http://localhost:8080/users/\(userId)",
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
                    id: response.id,
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
    let descriptor = FetchDescriptor<taskapeUser>(
        predicate: #Predicate<taskapeUser> { $0.id == userID }
    )

    do {
        let existingUsers = try context.fetch(descriptor)
        if existingUsers.isEmpty {
            context.insert(user)
        }
        try context.save()
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
    do {
        for remoteTask in tasks {
            let taskID = remoteTask.id  // Capture remoteTask.id in a constant
            let descriptor = FetchDescriptor<taskapeTask>(
                predicate: #Predicate<taskapeTask> { task in
                    task.id == taskID
                }
            )

            let existingTasks = try modelContext.fetch(descriptor)

            if let existingTask = existingTasks.first {
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

                // Associate with user if needed
                let remoteUserID = remoteTask.user_id  // Capture remoteTask.user_id in a constant
                let userDescriptor = FetchDescriptor<taskapeUser>(
                    predicate: #Predicate<taskapeUser> { user in
                        user.id == remoteUserID
                    }
                )

                if let user = try modelContext.fetch(userDescriptor).first {
                    user.tasks.append(remoteTask)
                }
            }
        }
        try modelContext.save()
    } catch {
        print("Failed to sync tasks: \(error)")
    }
}
