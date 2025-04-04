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
    var requiresConfirmation: Bool = false
    var isConfirmed: Bool = false
    var confirmedBy: String? = nil
    var confirmedAt: Date? = nil

    init(
        isCompleted: Bool = false, proofURL: String? = nil,
        requiresConfirmation: Bool = false, isConfirmed: Bool = false,
        confirmedBy: String? = nil, confirmedAt: Date? = nil
    ) {
        self.isCompleted = isCompleted
        self.proofURL = proofURL
        self.requiresConfirmation = requiresConfirmation
        self.isConfirmed = isConfirmed
        self.confirmedBy = confirmedBy
        self.confirmedAt = confirmedAt
    }
}

struct PrivacySettings: Codable {
    enum PrivacyLevel: String, Codable, CaseIterable {
        case everyone
        case friendsOnly = "friends-only"
        case group
        case noone
        case except
    }

    var level: PrivacyLevel
    var groupID: String?
    var exceptIDs: [String]

    enum CodingKeys: String, CodingKey {
        case level
        case groupID = "group_id"
        case exceptIDs = "except_ids"
    }

    init(
        level: PrivacyLevel = .everyone, groupID: String? = nil,
        exceptIDs: [String] = []
    ) {
        self.level = level
        self.groupID = groupID
        self.exceptIDs = exceptIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            let levelString = try container.decode(String.self, forKey: .level)
            if let level = PrivacyLevel(rawValue: levelString) {
                self.level = level
            } else {
                level = .everyone
            }
        } catch {
            level = .everyone
        }

        groupID = try container.decodeIfPresent(
            String.self, forKey: .groupID
        )

        do {
            exceptIDs = try container.decode(
                [String].self, forKey: .exceptIDs
            )
        } catch {
            exceptIDs = []
        }
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

    var privacyLevel: String = "everyone"
    var privacyGroupID: String?
    var privacyExceptIDs: [String] = []

    var flagStatus: Bool = false
    var flagColor: String? = nil
    var flagName: String? = nil
    var displayOrder: Int = 0

    var proofNeeded: Bool? = false
    var proofDescription: String? = nil
    var privacy: PrivacySettings {
        get {
            let level =
                PrivacySettings.PrivacyLevel(rawValue: privacyLevel)
                    ?? .everyone
            return PrivacySettings(
                level: level, groupID: privacyGroupID,
                exceptIDs: privacyExceptIDs
            )
        }
        set {
            privacyLevel = newValue.level.rawValue
            privacyGroupID = newValue.groupID
            privacyExceptIDs = newValue.exceptIDs
        }
    }

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
        mentioned_in_event: Bool = false,
        flagStatus: Bool = false,
        flagColor: String? = nil,
        flagName: String? = nil,
        displayOrder: Int = 0,
        proofNeeded: Bool? = false,
        proofDescription: String? = nil
    ) {
        self.id = id
        self.user_id = user_id
        self.name = name
        self.taskDescription = taskDescription
        self.author = author
        createdAt = Date()
        self.group = group
        self.group_id = group_id
        self.assignedToTask = assignedToTask
        self.task_difficulty = task_difficulty
        self.custom_hours = custom_hours
        self.mentioned_in_event = mentioned_in_event
        completion = CompletionStatus()
        self.privacy = privacy
        self.flagStatus = flagStatus
        self.flagColor = flagColor
        self.flagName = flagName
        self.displayOrder = displayOrder
        self.proofNeeded = proofNeeded
        self.proofDescription = proofDescription
    }

    func toggleFlag() {
        flagStatus.toggle()
        if !flagStatus {
            flagColor = nil
            flagName = nil
        } else if flagColor == nil {
            flagColor = "#FF6B6B"
            flagName = "High Priority"
        }
    }

    func setFlag(color: String, name: String) {
        flagColor = color
        flagName = name
        flagStatus = true
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
        mentioned_in_event: Bool = false,
        flagStatus: Bool = false,
        flagColor: String? = nil,
        flagName: String? = nil,
        displayOrder: Int = 0
    ) {
        let privacyLevel: PrivacySettings.PrivacyLevel = switch privacy.lowercased() {
        case "everyone", "public":
            .everyone
        case "friends-only", "friends":
            .friendsOnly
        case "group", "team":
            .group
        case "noone", "private":
            .noone
        case "except":
            .except
        default:
            .everyone
        }

        let privacySettings = PrivacySettings(
            level: privacyLevel, exceptIDs: []
        )

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
            mentioned_in_event: mentioned_in_event,
            flagStatus: flagStatus,
            flagColor: flagColor,
            flagName: flagName,
            displayOrder: displayOrder
        )
    }
}
