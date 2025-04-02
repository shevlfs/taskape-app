import Foundation
import SwiftData
import SwiftUI

@Model
final class taskapeUser {
    var id: String
    var handle: String
    var bio: String
    var profileImageURL: String
    var profileColor: String
    @Relationship var tasks: [taskapeTask]

    @Relationship var friends: [taskapeUser]
    var friendIds: [String]
    var incomingFriendRequestIds: [String]
    var outgoingFriendRequestIds: [String]

    init(
        id: String = UUID().uuidString,
        handle: String,
        bio: String,
        profileImage: String,
        profileColor: String
    ) {
        self.id = id
        self.handle = handle
        self.bio = bio
        self.profileImageURL = profileImage
        self.profileColor = profileColor
        self.tasks = []
        self.friends = []
        self.friendIds = []
        self.incomingFriendRequestIds = []
        self.outgoingFriendRequestIds = []
    }

    func addFriend(_ friend: taskapeUser) {
        if !friendIds.contains(friend.id) {
            friends.append(friend)
            friendIds.append(friend.id)
        }
    }

    func removeFriend(_ friendId: String) {
        friends.removeAll { $0.id == friendId }
        friendIds.removeAll { $0 == friendId }
    }

    func isFriend(_ userId: String) -> Bool {
        return friendIds.contains(userId)
    }

    func addIncomingFriendRequest(_ requestId: String) {
        if !incomingFriendRequestIds.contains(requestId) {
            incomingFriendRequestIds.append(requestId)
        }
    }

    func addOutgoingFriendRequest(_ requestId: String) {
        if !outgoingFriendRequestIds.contains(requestId) {
            outgoingFriendRequestIds.append(requestId)
        }
    }

    func removeFriendRequest(_ requestId: String, isIncoming: Bool) {
        if isIncoming {
            incomingFriendRequestIds.removeAll { $0 == requestId }
        } else {
            outgoingFriendRequestIds.removeAll { $0 == requestId }
        }
    }
}
