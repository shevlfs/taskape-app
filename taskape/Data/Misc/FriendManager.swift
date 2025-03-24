//
//  FriendManager.swift
//  taskape
//
//  Created by shevlfs on 3/24/25.
//

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
}
