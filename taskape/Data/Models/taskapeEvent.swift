

import Foundation
import SwiftData
import SwiftUI

enum EventType: String, Codable {
    case newTasksAdded = "new_tasks_added"
    case newlyReceived = "newly_received"
    case newlyCompleted = "newly_completed"
    case requiresConfirmation = "requires_confirmation"
    case nDayStreak = "n_day_streak"
    case deadlineComingUp = "deadline_coming_up"
}

enum EventSize: String, Codable {
    case small
    case medium
    case large
}

@Model
final class taskapeEvent: Identifiable {
    var id: String
    var userId: String
    var targetUserId: String
    var eventTypeRaw: String
    var eventSizeRaw: String
    var createdAt: Date
    var expiresAt: Date?
    var taskIds: [String]
    var streakDays: Int
    var likesCount: Int
    var commentsCount: Int
    var likedByUserIds: [String]

    var eventType: EventType {
        get {
            EventType(rawValue: eventTypeRaw) ?? .newTasksAdded
        }
        set {
            eventTypeRaw = newValue.rawValue
        }
    }

    var eventSize: EventSize {
        get {
            EventSize(rawValue: eventSizeRaw) ?? .medium
        }
        set {
            eventSizeRaw = newValue.rawValue
        }
    }

    @Relationship var relatedTasks: [taskapeTask] = []
    @Relationship var user: taskapeUser?

    init(
        id: String = UUID().uuidString,
        userId: String,
        targetUserId: String,
        eventType: EventType,
        eventSize: EventSize,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        taskIds: [String] = [],
        streakDays: Int = 0,
        likesCount: Int = 0,
        commentsCount: Int = 0,
        likedByUserIds: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.targetUserId = targetUserId
        eventTypeRaw = eventType.rawValue
        eventSizeRaw = eventSize.rawValue
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.taskIds = taskIds
        self.streakDays = streakDays
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.likedByUserIds = likedByUserIds
    }

    func isLikedByCurrentUser() -> Bool {
        let currentUserId = UserManager.shared.currentUserId
        return likedByUserIds.contains(currentUserId)
    }
}

@Model
final class EventComment: Identifiable {
    var id: String
    var eventId: String
    var userId: String
    var content: String
    var createdAt: Date
    var isEdited: Bool
    var editedAt: Date?

    @Relationship var user: taskapeUser?

    init(
        id: String = UUID().uuidString,
        eventId: String,
        userId: String,
        content: String,
        createdAt: Date = Date(),
        isEdited: Bool = false,
        editedAt: Date? = nil
    ) {
        self.id = id
        self.eventId = eventId
        self.userId = userId
        self.content = content
        self.createdAt = createdAt
        self.isEdited = isEdited
        self.editedAt = editedAt
    }
}
