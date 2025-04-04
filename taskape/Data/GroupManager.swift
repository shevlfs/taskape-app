import Foundation
import SwiftData
import SwiftUI

class GroupManager: ObservableObject {
    static let shared = GroupManager()

    @Published var isLoading: Bool = false
    @Published var groups: [taskapeGroup] = []
    @Published var selectedGroup: taskapeGroup? = nil
    @Published var groupInvitations: [GroupInvitation] = []

    func loadUserGroups(context: ModelContext) {
        let userId = UserManager.shared.currentUserId

        let descriptor = FetchDescriptor<taskapeGroup>(
            predicate: #Predicate<taskapeGroup> { group in
                group.members.contains(userId)
            }
        )

        do {
            groups = try context.fetch(descriptor)
        } catch {
            print("Error fetching groups: \(error)")
        }
    }

    func createGroup(name: String, description: String, color: String, context: ModelContext) async -> taskapeGroup? {
        isLoading = true
        defer { isLoading = false }

        let creatorId = UserManager.shared.currentUserId

        if let groupId = await taskape.createGroup(
            creatorId: creatorId,
            name: name,
            description: description,
            color: color
        ) {
            let newGroup = taskapeGroup(
                id: groupId,
                name: name,
                group_description: description,
                color: color,
                creatorId: creatorId
            )

            await MainActor.run {
                context.insert(newGroup)
                try? context.save()

                self.groups.append(newGroup)
                self.selectedGroup = newGroup
            }

            return newGroup
        }

        return nil
    }

    func inviteUserToGroup(groupId: String, inviteeId: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let inviterId = UserManager.shared.currentUserId

        if await inviteToGroup(groupId: groupId, inviterId: inviterId, inviteeId: inviteeId) != nil {
            return true
        }

        return false
    }

    func acceptGroupInvitation(inviteId: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let userId = UserManager.shared.currentUserId

        return await respondToGroupInvite(inviteId: inviteId, userId: userId, accept: true)
    }

    func rejectGroupInvitation(inviteId: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let userId = UserManager.shared.currentUserId

        return await respondToGroupInvite(inviteId: inviteId, userId: userId, accept: false)
    }

    func removeUserFromGroup(groupId: String, userId: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let adminId = UserManager.shared.currentUserId

        return await kickUserFromGroup(groupId: groupId, adminId: adminId, userId: userId)
    }

    func loadGroupTasks(groupId: String, context: ModelContext) async -> [taskapeTask] {
        isLoading = true
        defer { isLoading = false }

        let requesterId = UserManager.shared.currentUserId

        if let tasks = await getGroupTasks(groupId: groupId, requesterId: requesterId) {
            await MainActor.run {
                if let group = getGroupById(groupId: groupId, context: context) {
                    for task in tasks {
                        let taskId = task.id
                        let descriptor = FetchDescriptor<taskapeTask>(
                            predicate: #Predicate<taskapeTask> { $0.id == taskId }
                        )

                        do {
                            let existingTasks = try context.fetch(descriptor)

                            if existingTasks.isEmpty {
                                context.insert(task)
                                if !group.tasks.contains(where: { $0.id == task.id }) {
                                    group.tasks.append(task)
                                }
                            } else {
                                let existingTask = existingTasks[0]
                                updateTaskProperties(source: task, target: existingTask)

                                if !group.tasks.contains(where: { $0.id == existingTask.id }) {
                                    group.tasks.append(existingTask)
                                }
                            }
                        } catch {
                            print("Error processing task: \(error)")
                        }
                    }

                    try? context.save()
                }
            }

            return tasks
        }

        return []
    }

    private func getGroupById(groupId: String, context: ModelContext) -> taskapeGroup? {
        let descriptor = FetchDescriptor<taskapeGroup>(
            predicate: #Predicate<taskapeGroup> { $0.id == groupId }
        )

        do {
            let groups = try context.fetch(descriptor)
            return groups.first
        } catch {
            print("Error fetching group by ID: \(error)")
            return nil
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
