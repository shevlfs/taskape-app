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

    var friendTasks: [String: [taskapeTask]] = [:]

    func loadTasksForFriend(userId: String) async -> [taskapeTask]? {
        if let tasks = await fetchTasks(
            userId: userId)
        {
            friendTasks[userId] = tasks
            return tasks
        }

        return nil
    }

    func getTasksForFriend(userId: String) async -> [taskapeTask]? {
        if (friendTasks[userId] ?? []).isEmpty {
            return await loadTasksForFriend(userId: userId)
        }
        return friendTasks[userId]
    }

    func preloadAllFriendTasks() async {
        for friend in friends {
            _ = await loadTasksForFriend(userId: friend.id)
        }
    }

    func getTasksByIds(friendId: String, taskIds: [String]) async
        -> [taskapeTask]
    {
        if let allTasks = await getTasksForFriend(userId: friendId) {
            return allTasks.filter { taskIds.contains($0.id) }
        }
        return []
    }

    func clearTaskCache() {
        friendTasks.removeAll()
    }

    func searchUsers(query: String) async -> [UserSearchResult]? {
        await taskape.searchUsers(query: query)
    }

    func sendFriendRequest(to userId: String) async -> Bool {
        let success = await taskape.sendFriendRequest(receiverId: userId)
        if success {
            await refreshFriendDataBatched()
        }
        return success
    }

    func acceptFriendRequest(_ requestId: String) async -> Bool {
        let success = await respondToFriendRequest(
            requestId: requestId, response: "accept"
        )
        if success {
            await refreshFriendDataBatched()
        }
        return success
    }

    func rejectFriendRequest(_ requestId: String) async -> Bool {
        let success = await respondToFriendRequest(
            requestId: requestId, response: "reject"
        )
        if success {
            await MainActor.run {
                self.incomingRequests.removeAll { $0.id == requestId }
            }
        }
        return success
    }

    func isFriend(_ userId: String) -> Bool {
        friends.contains { $0.id == userId }
    }

    func hasPendingRequestTo(_ userId: String) -> Bool {
        outgoingRequests.contains { $0.receiver_id == userId }
    }

    func hasPendingRequestFrom(_ userId: String) -> Bool {
        incomingRequests.contains { $0.sender_id == userId }
    }

    var incomingRequestCount: Int {
        incomingRequests.count
    }
}
