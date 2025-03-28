import Foundation
import SwiftData
import SwiftUI

class FriendManager: ObservableObject {
    static let shared = FriendManager()

    @Published var friends: [Friend] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var outgoingRequests: [FriendRequest] = []
    @Published var isLoading: Bool = false

    func refreshFriendData() async {
        isLoading = true

        if let userId = UserDefaults.standard.string(forKey: "user_id"),
            let userFriends = await getUserFriends(userId: userId)
        {
            await MainActor.run {
                self.friends = userFriends
            }
        }

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

        await MainActor.run {
            self.isLoading = false
        }
    }

    // Add storage for friend tasks
    private var friendTasks: [String: [taskapeTask]] = [:]  // userId -> tasks

    // Function to load tasks for a friend
    func loadTasksForFriend(userId: String) async -> [taskapeTask]? {
        // Check if we already have tasks loaded
        if let tasks = friendTasks[userId], !tasks.isEmpty {
            return tasks
        }

        // If not, fetch them
        if let tasks = await fetchTasks(
            userId: userId)
        {
            // Store for future use
            friendTasks[userId] = tasks
            return tasks
        }

        return nil
    }

    // Get cached tasks for a friend, or fetch if needed
    func getTasksForFriend(userId: String) async -> [taskapeTask]? {
        if (friendTasks[userId] ?? []).isEmpty {
            return await loadTasksForFriend(userId: userId)
        }
        return friendTasks[userId]
    }

    // Preload tasks for all friends
    func preloadAllFriendTasks() async {
        for friend in friends {
            _ = await loadTasksForFriend(userId: friend.id)
        }
    }

    // Get specific tasks by ID for a friend
    func getTasksByIds(friendId: String, taskIds: [String]) async
        -> [taskapeTask]
    {
        if let allTasks = await getTasksForFriend(userId: friendId) {
            return allTasks.filter { taskIds.contains($0.id) }
        }
        return []
    }

    // Clear cached tasks
    func clearTaskCache() {
        friendTasks.removeAll()
    }

    func searchUsers(query: String) async -> [UserSearchResult]? {
        return await taskape.searchUsers(query: query)
    }

    func sendFriendRequest(to userId: String) async -> Bool {
        let success = await taskape.sendFriendRequest(receiverId: userId)
        if success {
            await refreshFriendData()
        }
        return success
    }

    func acceptFriendRequest(_ requestId: String) async -> Bool {
        let success = await respondToFriendRequest(
            requestId: requestId, response: "accept")
        if success {
            await refreshFriendData()
        }
        return success
    }

    func rejectFriendRequest(_ requestId: String) async -> Bool {
        let success = await respondToFriendRequest(
            requestId: requestId, response: "reject")
        if success {
            await MainActor.run {
                self.incomingRequests.removeAll { $0.id == requestId }
            }
        }
        return success
    }

    func isFriend(_ userId: String) -> Bool {
        return friends.contains { $0.id == userId }
    }

    func hasPendingRequestTo(_ userId: String) -> Bool {
        return outgoingRequests.contains { $0.receiver_id == userId }
    }

    func hasPendingRequestFrom(_ userId: String) -> Bool {
        return incomingRequests.contains { $0.sender_id == userId }
    }

    var incomingRequestCount: Int {
        return incomingRequests.count
    }
}
