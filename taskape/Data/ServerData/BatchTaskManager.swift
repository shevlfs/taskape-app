import Foundation
import SwiftData
import SwiftUI

// MARK: - Extensions for UserManager

extension UserManager {
    
    // Get multiple users in a batch request
    func fetchUsersBatch(userIds: [String]) async -> [taskapeUser]? {
        return await getUsersBatch(userIds: userIds)
    }
    
    // Save multiple users to the model context
    func saveUsersBatch(users: [taskapeUser], context: ModelContext) {
        for user in users {
            // Check if user already exists in the context
            let userid = user.id
            let descriptor = FetchDescriptor<taskapeUser>(
                predicate: #Predicate<taskapeUser> { $0.id == userid }
            )
            
            do {
                let existingUsers = try context.fetch(descriptor)
                if existingUsers.isEmpty {
                    context.insert(user)
                } else {
                    // Update existing user
                    let existingUser = existingUsers[0]
                    existingUser.handle = user.handle
                    existingUser.bio = user.bio
                    existingUser.profileImageURL = user.profileImageURL
                    existingUser.profileColor = user.profileColor
                }
            } catch {
                print("error checking for existing user: \(error)")
                context.insert(user)
            }
        }
        
        // Save context
        do {
            try context.save()
        } catch {
            print("error saving users batch: \(error)")
        }
    }
    
    // Edit current user's profile
    func updateCurrentUserProfile(
        handle: String? = nil,
        bio: String? = nil,
        color: String? = nil,
        profilePictureURL: String? = nil
    ) async -> Bool {
        guard !currentUserId.isEmpty else { return false }
        
        let success = await editUserProfile(
            userId: currentUserId,
            handle: handle,
            bio: bio,
            color: color,
            profilePictureURL: profilePictureURL
        )
        
        if success {
            // Update local model if successful
            DispatchQueue.main.async {
                if let context = ModelContainer.shared.mainContext as? ModelContext,
                   let user = self.getCurrentUser(context: context) {
                    
                    if let handle = handle { user.handle = handle }
                    if let bio = bio { user.bio = bio }
                    if let color = color { user.profileColor = color }
                    if let profilePictureURL = profilePictureURL { 
                        user.profileImageURL = profilePictureURL 
                    }
                    
                    do {
                        try context.save()
                    } catch {
                        print("error saving updated user profile: \(error)")
                    }
                }
            }
        }
        
        return success
    }
}

// MARK: - Extensions for Task Management

// Create a batch task manager to handle multiple users' tasks
class BatchTaskManager {
    static let shared = BatchTaskManager()
    
    // Fetch tasks for multiple users in a single request
    func fetchTasksForUsers(userIds: [String]) async -> [String: [taskapeTask]]? {
        let requesterId = UserManager.shared.currentUserId
        return await getUsersTasksBatch(userIds: userIds, requesterId: requesterId)
    }
    
    // Save multiple users' tasks to the model context
    func saveUsersTasks(userTasksMap: [String: [taskapeTask]], context: ModelContext) {
        for (userId, tasks) in userTasksMap {
            // First, fetch the user if it exists
            let userDescriptor = FetchDescriptor<taskapeUser>(
                predicate: #Predicate<taskapeUser> { $0.id == userId }
            )
            
            do {
                let users = try context.fetch(userDescriptor)
                let user = users.first
                
                // Process each task
                for task in tasks {
                    // Check if the task already exists
                    let taskid = task.id
                    let taskDescriptor = FetchDescriptor<taskapeTask>(
                        predicate: #Predicate<taskapeTask> { $0.id == taskid }
                    )
                    
                    let existingTasks = try context.fetch(taskDescriptor)
                    
                    if existingTasks.isEmpty {
                        // New task - insert into context
                        context.insert(task)
                        
                        // Associate with user if available
                        if let user = user, !user.tasks.contains(where: { $0.id == task.id }) {
                            user.tasks.append(task)
                        }
                    } else {
                        // Update existing task
                        let existingTask = existingTasks[0]
                        updateTaskProperties(source: task, target: existingTask)
                    }
                }
                
                // Save after processing each user's tasks
                try context.save()
                
            } catch {
                print("error processing tasks for user \(userId): \(error)")
            }
        }
    }
    
    // Helper function to update task properties
    private func updateTaskProperties(source: taskapeTask, target: taskapeTask) {
        target.name = source.name
        target.taskDescription = source.taskDescription
        target.deadline = source.deadline
        target.author = source.author
        target.group = source.group
        target.group_id = source.group_id
        target.assignedToTask = source.assignedToTask
        target.task_difficulty = source.task_difficulty
        target.custom_hours = source.custom_hours
        target.mentioned_in_event = source.mentioned_in_event
        target.completion = source.completion
        target.privacy = source.privacy
        target.flagStatus = source.flagStatus
        target.flagColor = source.flagColor
        target.flagName = source.flagName
        target.displayOrder = source.displayOrder
    }
}

// Updated refresh method for FriendManager
extension FriendManager {
    func refreshFriendDataBatched() async {
        isLoading = true

        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            // First, fetch the user's friends list
            if let userFriends = await getUserFriends(userId: userId) {
                await MainActor.run {
                    self.friends = userFriends
                }

                // Get all friend IDs for batch loading
                let friendIds = userFriends.map { $0.id }

                if !friendIds.isEmpty {
                    // Load all friends' tasks at once
                    if let batchedTasks = await BatchTaskManager.shared.fetchTasksForUsers(userIds: friendIds) {
                        await MainActor.run {
                            // Store fetched tasks in the cache
                            for (userId, tasks) in batchedTasks {
                                self.friendTasks[userId] = tasks
                            }
                        }
                    }
                }
            }

            // Fetch friend requests
            await loadFriendRequests()
        }

        await MainActor.run {
            self.isLoading = false
        }
    }

    private func loadFriendRequests() async {
        if let incoming = await getFriendRequests(type: "incoming") {
            await MainActor.run {
                self.incomingRequests = incoming
            }
        }

        if let outgoing = await getFriendRequests(type: "outgoing") {
            await MainActor.run {
                self.outgoingRequests = outgoing
            }
        }
    }

    // Replace the existing preloadAllFriendTasks method with this optimized version
    func preloadAllFriendTasksBatched() async {
        let friendIds = friends.map { $0.id }

        if !friendIds.isEmpty {
            if let batchedTasks = await BatchTaskManager.shared.fetchTasksForUsers(userIds: friendIds) {
                await MainActor.run {
                    // Store fetched tasks in the cache
                    for (userId, tasks) in batchedTasks {
                        self.friendTasks[userId] = tasks
                    }
                }
            }
        }
    }
}
