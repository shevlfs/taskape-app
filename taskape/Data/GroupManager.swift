import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import SwiftUI

class GroupManager: ObservableObject {
    static let shared = GroupManager()

    @Published var isLoading: Bool = false
    @Published var groups: [taskapeGroup] = []
    @Published var selectedGroup: taskapeGroup? = nil
    @Published var groupInvitations: [GroupInvitation] = []

    func createGroup(
        name: String, description: String, color: String, context: ModelContext
    ) async -> taskapeGroup? {
        await MainActor.run {
            isLoading = true
        }

        let creatorId = UserManager.shared.currentUserId
        var newGroup: taskapeGroup? = nil

        if let groupId = await taskape.createGroup(
            creatorId: creatorId,
            name: name,
            description: description,
            color: color
        ) {
            let group = taskapeGroup(
                id: groupId,
                name: name,
                group_description: description,
                color: color,
                creatorId: creatorId
            )

            group.members = [creatorId]
            group.admins = [creatorId]

            await MainActor.run {
                insertGroupInContext(group: group, context: context)
            }

            newGroup = group
        }

        await MainActor.run {
            isLoading = false
        }

        return newGroup
    }

    private func insertGroupInContext(
        group: taskapeGroup, context: ModelContext
    ) {
        context.insert(group)
        let gid = group.creatorId
        let userDescriptor = FetchDescriptor<taskapeUser>(
            predicate: #Predicate<taskapeUser> { user in
                user.id == gid
            }
        )

        do {
            let users = try context.fetch(userDescriptor)
            if let currentUser = users.first {
                group.users.append(currentUser)
            }

            try context.save()

            groups.append(group)
            selectedGroup = group
        } catch {
            print("Error setting up group relationships: \(error)")
        }
    }

    func inviteUserToGroup(groupId: String, inviteeId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }

        let inviterId = UserManager.shared.currentUserId
        let result =
            await inviteToGroup(
                groupId: groupId, inviterId: inviterId, inviteeId: inviteeId
            )
            != nil

        await MainActor.run {
            isLoading = false
        }

        return result
    }

    func acceptGroupInvitation(inviteId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }

        let userId = UserManager.shared.currentUserId
        let accepted = await respondToGroupInvite(
            inviteId: inviteId, userId: userId, accept: true
        )

        if accepted {
            await refreshGroups()
        }

        await MainActor.run {
            isLoading = false
        }

        return accepted
    }

    func rejectGroupInvitation(inviteId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }

        let userId = UserManager.shared.currentUserId
        let result = await respondToGroupInvite(
            inviteId: inviteId, userId: userId, accept: false
        )

        await MainActor.run {
            isLoading = false
        }

        return result
    }

    func removeUserFromGroup(groupId: String, userId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
        }

        let adminId = UserManager.shared.currentUserId
        let success = await kickUserFromGroup(
            groupId: groupId, adminId: adminId, userId: userId
        )

        if success {
            await MainActor.run {
                if let groupIndex = groups.firstIndex(where: {
                    $0.id == groupId
                }) {
                    let group = groups[groupIndex]
                    if let memberIndex = group.members.firstIndex(of: userId) {
                        group.members.remove(at: memberIndex)
                    }
                    group.users.removeAll { $0.id == userId }
                }
            }
        }

        await MainActor.run {
            isLoading = false
        }

        return success
    }

    func loadGroupMembers(group: taskapeGroup, context: ModelContext) async {
        if group.members.count == group.users.count,
           group.members.allSatisfy({ memberId in
               group.users.contains(where: { $0.id == memberId })
           })
        {
            return
        }

        let membersToLoad = group.members.filter { memberId in
            !group.users.contains(where: { $0.id == memberId })
        }

        if membersToLoad.isEmpty {
            return
        }

        if let userResponses = await getUsersBatch(userIds: membersToLoad) {
            await MainActor.run {
                for response in userResponses {
                    let respid = response.id
                    let userDescriptor = FetchDescriptor<taskapeUser>(
                        predicate: #Predicate<taskapeUser> { $0.id == respid }
                    )

                    do {
                        let existingUsers = try context.fetch(userDescriptor)

                        if let existingUser = existingUsers.first {
                            existingUser.handle = response.handle
                            existingUser.bio = response.bio
                            existingUser.profileImageURL =
                                response.profileImageURL
                            existingUser.profileColor = response.profileColor

                            if !group.users.contains(where: {
                                $0.id == existingUser.id
                            }) {
                                group.users.append(existingUser)
                            }
                        } else {
                            let newUser = taskapeUser(
                                id: response.id,
                                handle: response.handle,
                                bio: response.bio,
                                profileImage: response.profileImageURL,
                                profileColor: response.profileColor
                            )

                            context.insert(newUser)
                            group.users.append(newUser)
                        }
                    } catch {
                        print("Error checking for existing user: \(error)")

                        let newUser = taskapeUser(
                            id: response.id,
                            handle: response.handle,
                            bio: response.bio,
                            profileImage: response.profileImageURL,
                            profileColor: response.profileColor
                        )

                        context.insert(newUser)
                        group.users.append(newUser)
                    }
                }

                try? context.save()
            }
        }
        await FriendManager.shared.refreshFriendDataBatched()
    }

    func loadGroupTasks(groupId: String, context: ModelContext) async -> [taskapeTask] {
        print("Loading tasks for group: \(groupId)")

        await MainActor.run {
            isLoading = true
        }

        let requesterId = UserManager.shared.currentUserId
        var resultTasks: [taskapeTask] = []

        await MainActor.run {
            let taskDescriptor = FetchDescriptor<taskapeTask>(
                predicate: #Predicate<taskapeTask> { task in
                    task.group_id == groupId
                }
            )

            do {
                resultTasks = try context.fetch(taskDescriptor)
                print("Found \(resultTasks.count) tasks locally for group \(groupId)")
            } catch {
                print("Error fetching local tasks: \(error)")
            }
        }

        if let tasks = await getGroupTasks(groupId: groupId, requesterId: requesterId) {
            print("Fetched \(tasks.count) tasks from server for group \(groupId)")

            await MainActor.run {
                if let group = getGroupById(groupId: groupId, context: context) {
                    group.tasks = []

                    for task in tasks {
                        let taskId = task.id
                        let descriptor = FetchDescriptor<taskapeTask>(
                            predicate: #Predicate<taskapeTask> { $0.id == taskId }
                        )

                        do {
                            let existingTasks = try context.fetch(descriptor)

                            if existingTasks.isEmpty {
                                context.insert(task)
                                group.tasks.append(task)
                            } else {
                                let existingTask = existingTasks[0]
                                updateTaskProperties(source: task, target: existingTask)

                                if !group.tasks.contains(where: { $0.id == existingTask.id }) {
                                    group.tasks.append(existingTask)
                                }
                            }
                        } catch {
                            print("Error processing task \(taskId): \(error)")
                        }
                    }

                    do {
                        try context.save()
                        resultTasks = group.tasks
                        print("Saved \(resultTasks.count) tasks for group \(groupId)")
                    } catch {
                        print("Error saving tasks for group \(groupId): \(error)")
                    }
                } else {
                    print("Group not found in context: \(groupId)")
                }
            }
        } else {
            print("Failed to fetch tasks from server for group \(groupId)")
        }

        await MainActor.run {
            isLoading = false
        }

        await FriendManager.shared.refreshFriendDataBatched()

        return resultTasks
    }

    func fetchUserGroups(context: ModelContext) async {
        print("Starting group data fetch...")

        await MainActor.run {
            isLoading = true
        }

        let userId = UserManager.shared.currentUserId
        print("Fetching groups for user ID: \(userId)")

        if let remoteGroups = await getUserGroups(userId: userId) {
            print("Retrieved \(remoteGroups.count) groups from server")

            await MainActor.run {
                syncGroups(remoteGroups: remoteGroups, context: context)
                self.groups = remoteGroups
                print("Updated GroupManager.groups with \(remoteGroups.count) groups")
            }

            for group in remoteGroups {
                print("Processing group: \(group.id) - \(group.name)")

                await loadGroupMembers(group: group, context: context)

                let tasks = await getGroupTasks(groupId: group.id, requesterId: userId)

                let allMemberIds = group.members
                var allMemberTasks: [taskapeTask] = []

                if !allMemberIds.isEmpty {
                    print("Fetching tasks for \(allMemberIds.count) members in group \(group.name)")
                    if let memberTasks = await BatchTaskManager.shared.fetchTasksForUsers(userIds: allMemberIds) {
                        for (memberId, memberTaskList) in memberTasks {
                            allMemberTasks.append(contentsOf: memberTaskList)
                            print("Fetched \(memberTaskList.count) tasks for member \(memberId)")
                        }
                    }
                }

                await MainActor.run {
                    if let localGroup = getGroupById(groupId: group.id, context: context) {
                        if let fetchedTasks = tasks {
                            print("Fetched \(fetchedTasks.count) tasks for group: \(group.name)")

                            localGroup.tasks = []

                            for task in fetchedTasks {
                                let taskId = task.id
                                let descriptor = FetchDescriptor<taskapeTask>(
                                    predicate: #Predicate<taskapeTask> { $0.id == taskId }
                                )

                                do {
                                    let existingTasks = try context.fetch(descriptor)

                                    if existingTasks.isEmpty {
                                        context.insert(task)
                                        localGroup.tasks.append(task)
                                    } else {
                                        let existingTask = existingTasks[0]
                                        updateTaskProperties(source: task, target: existingTask)

                                        if !localGroup.tasks.contains(where: { $0.id == existingTask.id }) {
                                            localGroup.tasks.append(existingTask)
                                        }
                                    }
                                } catch {
                                    print("Error processing task: \(error)")
                                }
                            }
                        }

                        for task in allMemberTasks {
                            if task.group_id == group.id {
                                let taskId = task.id

                                if !localGroup.tasks.contains(where: { $0.id == taskId }) {
                                    let descriptor = FetchDescriptor<taskapeTask>(
                                        predicate: #Predicate<taskapeTask> { $0.id == taskId }
                                    )

                                    do {
                                        let existingTasks = try context.fetch(descriptor)

                                        if existingTasks.isEmpty {
                                            context.insert(task)
                                            localGroup.tasks.append(task)
                                        } else {
                                            let existingTask = existingTasks[0]
                                            updateTaskProperties(source: task, target: existingTask)

                                            if !localGroup.tasks.contains(where: { $0.id == existingTask.id }) {
                                                localGroup.tasks.append(existingTask)
                                            }
                                        }
                                    } catch {
                                        print("Error processing member task: \(error)")
                                    }
                                }
                            }
                        }

                        try? context.save()
                        print("Successfully saved \(localGroup.tasks.count) tasks for group: \(group.name)")
                    } else {
                        print("Could not find local group with ID: \(group.id)")
                    }
                }
            }
        } else {
            print("Failed to retrieve groups or user has no groups")
        }

        await MainActor.run {
            isLoading = false
            print("Group data fetch completed")
        }
    }

    private func syncGroups(remoteGroups: [taskapeGroup], context: ModelContext) {
        print("Syncing \(remoteGroups.count) groups with local database")

        for remoteGroup in remoteGroups {
            let groupId = remoteGroup.id
            let descriptor = FetchDescriptor<taskapeGroup>(
                predicate: #Predicate<taskapeGroup> { $0.id == groupId }
            )

            do {
                let existingGroups = try context.fetch(descriptor)

                if existingGroups.isEmpty {
                    context.insert(remoteGroup)
                    print("Added new group: \(remoteGroup.name) (ID: \(remoteGroup.id))")
                } else {
                    let existingGroup = existingGroups[0]
                    existingGroup.name = remoteGroup.name
                    existingGroup.group_description = remoteGroup.group_description
                    existingGroup.color = remoteGroup.color
                    existingGroup.members = remoteGroup.members
                    existingGroup.admins = remoteGroup.admins
                    print("Updated existing group: \(existingGroup.name) (ID: \(existingGroup.id))")
                }
            } catch {
                print("Error syncing group \(remoteGroup.name): \(error)")
            }
        }

        do {
            let allLocalGroups = try context.fetch(FetchDescriptor<taskapeGroup>())
            let remoteGroupIds = Set(remoteGroups.map(\.id))

            for localGroup in allLocalGroups {
                if !remoteGroupIds.contains(localGroup.id) {
                    context.delete(localGroup)
                    print("Deleted group that no longer exists: \(localGroup.name) (ID: \(localGroup.id))")
                }
            }

            try context.save()
            print("Successfully saved group sync changes")
        } catch {
            print("Error cleaning up groups: \(error)")
        }
    }

    func refreshGroups() async {
        await MainActor.run {
            self.objectWillChange.send()
        }
    }

    func getGroupById(groupId: String, context: ModelContext) -> taskapeGroup? {
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
        target.proofNeeded = source.proofNeeded
        target.proofDescription = source.proofDescription
    }

    func createTaskInGroup(
        task: taskapeTask, groupId: String, context: ModelContext
    ) async -> Bool {
        guard let group = getGroupById(groupId: groupId, context: context)
        else {
            return false
        }

        task.group_id = groupId
        task.group = group.name

        let taskData = TaskSubmission(
            id: task.id,
            user_id: task.user_id,
            name: task.name,
            description: task.taskDescription,
            deadline: task.deadline != nil
                ? ISO8601DateFormatter().string(from: task.deadline!) : nil,
            author: task.author,
            group: task.group,
            group_id: task.group_id,
            assigned_to: task.assignedToTask,
            difficulty: task.task_difficulty.rawValue,
            is_completed: task.completion.isCompleted,
            custom_hours: task.custom_hours,
            privacy_level: getPrivacyLevel(task.privacy),
            privacy_except_ids: task.privacy.exceptIDs,
            flag_status: task.flagStatus,
            flag_color: task.flagColor,
            flag_name: task.flagName,
            display_order: task.displayOrder,
            proof_needed: task.proofNeeded ?? false,
            proof_description: task.proofDescription,
            requires_confirmation: task.completion.requiresConfirmation,
            is_confirmed: task.completion.isConfirmed
        )

        guard let token = UserDefaults.standard.string(forKey: "authToken")
        else {
            print("No auth token found")
            return false
        }

        let request = BatchTaskSubmissionRequest(
            tasks: [taskData],
            token: token
        )

        do {
            let result = await AF.request(
                "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/submitTasksBatch",
                method: .post,
                parameters: request,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .serializingDecodable(BatchTaskSubmissionResponse.self)
            .response

            switch result.result {
            case let .success(response):
                if response.success, let newTaskId = response.task_ids.first {
                    task.id = newTaskId

                    await MainActor.run {
                        context.insert(task)
                        group.tasks.append(task)
                        try? context.save()
                    }
                    return true
                }
                return false
            case .failure:
                return false
            }
        }
    }

    private func getPrivacyLevel(_ privacy: PrivacySettings) -> String {
        switch privacy.level {
        case .everyone:
            "everyone"
        case .friendsOnly:
            "friends-only"
        case .group:
            "group"
        case .noone:
            "noone"
        case .except:
            "except"
        }
    }
}
