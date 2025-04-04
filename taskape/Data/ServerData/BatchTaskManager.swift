import Foundation
import SwiftData
import SwiftUI

extension UserManager {
    func fetchUsersBatch(userIds: [String]) async -> [taskapeUser]? {
        await getUsersBatch(userIds: userIds)
    }

    func saveUsersBatch(users: [taskapeUser], context: ModelContext) {
        for user in users {
            let userid = user.id
            let descriptor = FetchDescriptor<taskapeUser>(
                predicate: #Predicate<taskapeUser> { $0.id == userid }
            )

            do {
                let existingUsers = try context.fetch(descriptor)
                if existingUsers.isEmpty {
                    context.insert(user)
                } else {
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

        do {
            try context.save()
        } catch {
            print("error saving users batch: \(error)")
        }
    }

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
            DispatchQueue.main.async {
                if let context = ModelContainer.shared.mainContext as? ModelContext,
                   let user = self.getCurrentUser(context: context)
                {
                    if let handle { user.handle = handle }
                    if let bio { user.bio = bio }
                    if let color { user.profileColor = color }
                    if let profilePictureURL {
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

class BatchTaskManager {
    static let shared = BatchTaskManager()

    func fetchTasksForUsers(userIds: [String]) async -> [String: [taskapeTask]]? {
        let requesterId = UserManager.shared.currentUserId
        return await getUsersTasksBatch(userIds: userIds, requesterId: requesterId)
    }

    func saveUsersTasks(userTasksMap: [String: [taskapeTask]], context: ModelContext) {
        for (userId, tasks) in userTasksMap {
            let userDescriptor = FetchDescriptor<taskapeUser>(
                predicate: #Predicate<taskapeUser> { $0.id == userId }
            )

            do {
                let users = try context.fetch(userDescriptor)
                let user = users.first

                for task in tasks {
                    let taskid = task.id
                    let taskDescriptor = FetchDescriptor<taskapeTask>(
                        predicate: #Predicate<taskapeTask> { $0.id == taskid }
                    )

                    let existingTasks = try context.fetch(taskDescriptor)

                    if existingTasks.isEmpty {
                        context.insert(task)

                        if let user, !user.tasks.contains(where: { $0.id == task.id }) {
                            user.tasks.append(task)
                        }
                    } else {
                        let existingTask = existingTasks[0]
                        updateTaskProperties(source: task, target: existingTask)
                    }
                }

                try context.save()

            } catch {
                print("error processing tasks for user \(userId): \(error)")
            }
        }
    }

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

extension FriendManager {
    func refreshFriendDataBatched() async {
        isLoading = true

        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            if let userFriends = await getUserFriends(userId: userId) {
                await MainActor.run {
                    self.friends = userFriends
                }

                let friendIds = userFriends.map(\.id)

                if !friendIds.isEmpty {
                    if let batchedTasks = await BatchTaskManager.shared.fetchTasksForUsers(userIds: friendIds) {
                        await MainActor.run {
                            for (userId, tasks) in batchedTasks {
                                self.friendTasks[userId] = tasks
                            }
                        }
                    }
                }
            }

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

    func preloadAllFriendTasksBatched() async {
        let friendIds = friends.map(\.id)

        if !friendIds.isEmpty {
            if let batchedTasks = await BatchTaskManager.shared.fetchTasksForUsers(userIds: friendIds) {
                await MainActor.run {
                    for (userId, tasks) in batchedTasks {
                        self.friendTasks[userId] = tasks
                    }
                }
            }
        }
    }
}
