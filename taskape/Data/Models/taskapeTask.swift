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
        case everyone
        case friendsOnly = "friends-only"
        case group
        case noone
    }

    var level: PrivacyLevel
    var exceptIDs: [String]

    init(level: PrivacyLevel = .everyone, exceptIDs: [String] = []) {
        self.level = level
        self.exceptIDs = exceptIDs
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
        privacy: String,
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

        switch privacy {
        case "public":
            self.privacy = PrivacySettings(level: .everyone)
        case "private":
            self.privacy = PrivacySettings(level: .noone)
        default:
            self.privacy = PrivacySettings(level: .everyone)
        }
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
        }
    }
}
