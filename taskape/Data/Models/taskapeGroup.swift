import Foundation
import SwiftData

@Model
final class taskapeGroup: Identifiable {
    var id: String
    var name: String
    var group_description: String
    var color: String
    var creatorId: String
    var createdAt: Date

    var members: [String] = []
    var admins: [String] = []

    @Relationship var tasks: [taskapeTask] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        group_description: String,
        color: String,
        creatorId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.group_description = group_description
        self.color = color
        self.creatorId = creatorId
        self.createdAt = createdAt
        members = [creatorId]
        admins = [creatorId]
    }

    func isAdmin(userId: String) -> Bool {
        admins.contains(userId)
    }

    func isMember(userId: String) -> Bool {
        members.contains(userId)
    }

    func addMember(userId: String, isAdmin: Bool = false) {
        if !members.contains(userId) {
            members.append(userId)
        }

        if isAdmin, !admins.contains(userId) {
            admins.append(userId)
        }
    }

    func removeMember(userId: String) {
        members.removeAll { $0 == userId }
        admins.removeAll { $0 == userId }
    }
}
