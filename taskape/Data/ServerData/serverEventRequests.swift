import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import SwiftUI

func fetchEvents(userId: String, includeExpired: Bool = false, limit: Int = 20)
    async -> [taskapeEvent]?
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token,
        ]

        var urlComponents = URLComponents(
            string:
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/events"
        )
        urlComponents?.queryItems = [
            URLQueryItem(
                name: "include_expired",
                value: includeExpired ? "true" : "false"
            ),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]

        guard let url = urlComponents?.url else {
            print("invalid url components")
            return nil
        }

        let result = await AF.request(
            url,
            method: .get,
            headers: headers
        )
        .validate()
        .responseData { response in

            if let data = response.data {
                do {
                    let decoded = try JSONDecoder().decode(
                        GetEventsResponse.self, from: data
                    )

                } catch {
                    print("Decode error: \(error)")

                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case let .keyNotFound(key, context):
                            print(
                                "Missing key: \(key), path: \(context.codingPath)"
                            )
                        case let .typeMismatch(type, context):
                            print(
                                "Type mismatch: expected \(type), path: \(context.codingPath)"
                            )
                        case let .valueNotFound(type, context):
                            print(
                                "Value not found: expected \(type), path: \(context.codingPath)"
                            )
                        default:
                            print("Other decoding error: \(decodingError)")
                        }
                    }
                }
            }
        }
        .serializingDecodable(GetEventsResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                let events = response.events.map { convertToLocalEvent($0) }
                return events
            } else {
                print(
                    "failed to fetch events: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to fetch events: \(error.localizedDescription)")
            return nil
        }
    }
}

func likeEvent(eventId: String, userId: String) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    let request = LikeEventRequest(
        user_id: userId,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/like",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: [
                "Authorization": token,
            ]
        )
        .validate()
        .serializingDecodable(LikeEventResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print("failed to like event: \(error.localizedDescription)")
            return false
        }
    }
}

func unlikeEvent(eventId: String, userId: String) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    var urlComponents = URLComponents(
        string:
        "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/like")
    urlComponents?.queryItems = [
        URLQueryItem(name: "user_id", value: userId),
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return false
    }

    let headers: HTTPHeaders = [
        "Authorization": token,
    ]

    do {
        let result = await AF.request(
            url,
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingDecodable(LikeEventResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print("failed to unlike event: \(error.localizedDescription)")
            return false
        }
    }
}

func fetchEventComments(eventId: String, limit: Int = 20, offset: Int = 0) async
    -> [EventComment]?
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    var urlComponents = URLComponents(
        string:
        "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/comments"
    )
    urlComponents?.queryItems = [
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "offset", value: "\(offset)"),
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return nil
    }

    let headers: HTTPHeaders = [
        "Authorization": token,
    ]

    do {
        let result = await AF.request(
            url,
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(GetEventCommentsResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                let comments = response.comments.map {
                    convertToLocalComment($0)
                }
                return comments
            } else {
                print(
                    "failed to fetch comments: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to fetch comments: \(error.localizedDescription)")
            return nil
        }
    }
}

struct AddEventCommentResponse: Codable {
    let success: Bool
    let comment: EventCommentResponse
    let message: String?
}

func addEventComment(eventId: String, userId: String, content: String) async
    -> EventComment?
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    let request = AddEventCommentRequest(
        user_id: userId,
        content: content,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/comments",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: [
                "Authorization": token,
            ]
        )
        .validate()
        .serializingDecodable(AddEventCommentResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                return convertToLocalComment(response.comment)
            } else {
                print(
                    "failed to add comment: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to add comment: \(error.localizedDescription)")
            return nil
        }
    }
}

struct DeleteEventCommentResponse: Codable {
    let success: Bool
    let message: String?
}

func deleteEventComment(eventId: String, commentId: String, userId: String)
    async -> Bool
{
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    var urlComponents = URLComponents(
        string:
        "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/comments/\(commentId)"
    )
    urlComponents?.queryItems = [
        URLQueryItem(name: "user_id", value: userId),
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return false
    }

    let headers: HTTPHeaders = [
        "Authorization": token,
    ]

    do {
        let result = await AF.request(
            url,
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingDecodable(DeleteEventCommentResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print("failed to delete comment: \(error.localizedDescription)")
            return false
        }
    }
}

func confirmTaskCompletion(
    taskId: String, confirmerId: String, isConfirmed: Bool
) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    let request = ConfirmTaskCompletionRequest(
        task_id: taskId,
        confirmer_id: confirmerId,
        is_confirmed: isConfirmed,
        token: token
    )

    do {
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/confirmTaskCompletion",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(ConfirmTaskCompletionResponse.self)
        .response

        switch result.result {
        case let .success(response):
            return response.success
        case let .failure(error):
            print(
                "failed to confirm task completion: \(error.localizedDescription)"
            )
            return false
        }
    }
}

func convertToLocalEvent(_ event: EventResponse) -> taskapeEvent {
    let dateFormatter = ISO8601DateFormatter()

    let createdAt = dateFormatter.date(from: event.created_at) ?? Date()

    var expiresAt: Date?
    if let expiresAtStr = event.expires_at {
        expiresAt = dateFormatter.date(from: expiresAtStr)
    }

    let eventType = EventType(rawValue: event.type) ?? .newTasksAdded
    let eventSize = EventSize(rawValue: event.size) ?? .medium

    return taskapeEvent(
        id: event.id,
        userId: event.user_id,
        targetUserId: event.target_user_id,
        eventType: eventType,
        eventSize: eventSize,
        createdAt: createdAt,
        expiresAt: expiresAt,
        taskIds: event.task_ids ?? [],
        streakDays: event.streak_days,
        likesCount: event.likes_count,
        commentsCount: event.comments_count,
        likedByUserIds: event.liked_by_user_ids ?? []
    )
}

func convertToLocalComment(_ comment: EventCommentResponse) -> EventComment {
    let dateFormatter = ISO8601DateFormatter()

    let createdAt = dateFormatter.date(from: comment.created_at) ?? Date()

    var editedAt: Date? = nil
    if let editedAtStr = comment.edited_at {
        editedAt = dateFormatter.date(from: editedAtStr)
    }

    return EventComment(
        id: comment.id,
        eventId: comment.event_id,
        userId: comment.user_id,
        content: comment.content,
        createdAt: createdAt,
        isEdited: comment.is_edited,
        editedAt: editedAt
    )
}

func loadRelatedTasksForEvents(
    events: [taskapeEvent], modelContext: ModelContext
) {
    var allTaskIds = Set<String>()
    for event in events {
        allTaskIds.formUnion(event.taskIds)
    }

    if allTaskIds.isEmpty {
        return
    }

    for taskId in allTaskIds {
        let taskDescriptor = FetchDescriptor<taskapeTask>(
            predicate: #Predicate<taskapeTask> { task in
                task.id == taskId
            }
        )

        do {
            let existingTasks = try modelContext.fetch(taskDescriptor)
            if !existingTasks.isEmpty {
                let task = existingTasks[0]
                for event in events where event.taskIds.contains(taskId) {
                    if !event.relatedTasks.contains(where: { $0.id == task.id }) {
                        event.relatedTasks.append(task)
                    }
                }
            }
        } catch {
            print("error checking for existing task: \(error)")
        }
    }
}

func loadRelatedTasksForEventsSelf(
    events: [taskapeEvent], existingTasks: [taskapeTask]
) {
    let tasksById = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })

    for event in events {
        for taskId in event.taskIds {
            if let task = tasksById[taskId] {
                if !event.relatedTasks.contains(where: { $0.id == task.id }) {
                    event.relatedTasks.append(task)
                }
            }
        }
    }
}

func fetchUserRelatedEvents(
    userId: String, includeExpired: Bool = true, limit: Int = 50
) async -> [taskapeEvent]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    let currentUserId = UserManager.shared.currentUserId

    do {
        let headers: HTTPHeaders = [
            "Authorization": token,
        ]

        var urlComponents = URLComponents(
            string:
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/relatedEvents"
        )
        urlComponents?.queryItems = [
            URLQueryItem(
                name: "include_expired",
                value: includeExpired ? "true" : "false"
            ),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "requester_id", value: currentUserId),
        ]

        guard let url = urlComponents?.url else {
            print("invalid url components")
            return nil
        }

        let result = await AF.request(
            url,
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(GetEventsResponse.self)
        .response

        switch result.result {
        case let .success(response):
            if response.success {
                let events = response.events.map { convertToLocalEvent($0) }
                return events
            } else {
                print(
                    "failed to fetch events: \(response.message ?? "unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print("failed to fetch events: \(error.localizedDescription)")
            return nil
        }
    }
}
