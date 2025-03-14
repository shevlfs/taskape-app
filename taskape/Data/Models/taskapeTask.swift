//
//  Item.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import Foundation
import SwiftData
import SwiftUICore

enum TaskDifficulty: String, Codable {
    case small
    case medium
    case large
    case custom
}

struct CompletionStatus: Codable {
    var isCompleted: Bool
    var proofURL: String?

    init(isCompleted: Bool = false, proofURL: String? = nil) {
        self.isCompleted = isCompleted
        self.proofURL = proofURL
    }
}

struct PrivacySettings: Codable {
    enum PrivacyLevel: String, Codable {
        case everyone = "everyone"
        case friendsOnly = "friends-only"
        case group = "group"
        case noone = "noone"
        case except = "except"
    }

    var level: PrivacyLevel
    var groupID: String?
    var exceptIDs: [String]

    // Custom Codable implementation to ensure proper serialization
    enum CodingKeys: String, CodingKey {
        case level
        case groupID = "group_id"
        case exceptIDs = "except_ids"
    }

    init(level: PrivacyLevel = .everyone, groupID: String? = nil, exceptIDs: [String] = []) {
        self.level = level
        self.groupID = groupID
        self.exceptIDs = exceptIDs
    }

    // Convenience initializer from string
    init(from string: String) {
        switch string.lowercased() {
        case "everyone", "public":
            self.level = .everyone
        case "friends-only", "friends":
            self.level = .friendsOnly
        case "group", "team":
            self.level = .group
        case "noone", "private":
            self.level = .noone
        case "except":
            self.level = .except
        default:
            self.level = .everyone
        }
        self.groupID = nil
        self.exceptIDs = []
    }

    // String representation for debugging and API
    func toString() -> String {
        return level.rawValue
    }
}


@Model
final class taskapeTask: Identifiable {
    var id: String
    var user_id: String
    var name: String
    var taskDescription: String
    var createdAt: Date
    var deadline: Date?
    var author: String
    var group: String?
    var group_id: String?
    var assignedToTask: [String]
    var task_difficulty: TaskDifficulty
    var custom_hours: Int?
    var mentioned_in_event: Bool
    var completion: CompletionStatus
    var privacy: PrivacySettings

    init(
        id: String = UUID().uuidString,
        user_id: String = "",
        name: String,
        taskDescription: String,
        author: String,
        privacy: PrivacySettings,
        group: String? = nil,
        group_id: String? = nil,
        assignedToTask: [String] = [],
        task_difficulty: TaskDifficulty = .medium,
        custom_hours: Int? = nil,
        mentioned_in_event: Bool = false
    ) {
        self.id = id
        self.user_id = user_id
        self.name = name
        self.taskDescription = taskDescription
        self.author = author
        self.createdAt = Date()
        self.group = group
        self.group_id = group_id
        self.assignedToTask = assignedToTask
        self.task_difficulty = task_difficulty
        self.custom_hours = custom_hours
        self.mentioned_in_event = mentioned_in_event
        self.completion = CompletionStatus()
        self.privacy = privacy
    }

    func markAsCompleted(proofURL: String? = nil) {
        self.completion = CompletionStatus(
            isCompleted: true, proofURL: proofURL)
    }

    func getPrivacyString() -> String {
        switch privacy.level {
        case .everyone:
            return "public"
        case .noone:
            return "private"
        case .friendsOnly:
            return "friends-only"
        case .group:
            return "group"
        case .except:
            return "except"
        }
    }
}

extension taskapeTask {
    convenience init(
        id: String = UUID().uuidString,
        user_id: String = "",
        name: String,
        taskDescription: String,
        author: String,
        privacy: String,
        group: String? = nil,
        group_id: String? = nil,
        assignedToTask: [String] = [],
        task_difficulty: TaskDifficulty = .medium,
        custom_hours: Int? = nil,
        mentioned_in_event: Bool = false
    ) {
        let privacyLevel: PrivacySettings.PrivacyLevel
        switch privacy.lowercased() {
        case "everyone", "public":
            privacyLevel = .everyone
        case "friends-only", "friends":
            privacyLevel = .friendsOnly
        case "group", "team":
            privacyLevel = .group
        case "noone", "private":
            privacyLevel = .noone
        case "except":
            privacyLevel = .except
        default:
            privacyLevel = .everyone
        }

        let privacySettings = PrivacySettings(level: privacyLevel, exceptIDs: [])

        self.init(
            id: id,
            user_id: user_id,
            name: name,
            taskDescription: taskDescription,
            author: author,
            privacy: privacySettings,
            group: group,
            group_id: group_id,
            assignedToTask: assignedToTask,
            task_difficulty: task_difficulty,
            custom_hours: custom_hours,
            mentioned_in_event: mentioned_in_event
        )
    }
}

// 2. Add helper extension to convert string privacy level to enum
extension String {
    func toPrivacyLevel() -> PrivacySettings.PrivacyLevel {
        switch self.lowercased() {
        case "everyone", "public":
            return .everyone
        case "friends-only", "friends":
            return .friendsOnly
        case "group", "team":
            return .group
        case "noone", "private":
            return .noone
        case "except":
            return .except
        default:
            return .everyone
        }
    }
}

// 3. Add extension for creating PrivacySettings from string
extension PrivacySettings {
    static func from(string: String) -> PrivacySettings {
        return PrivacySettings(level: string.toPrivacyLevel())
    }
}
