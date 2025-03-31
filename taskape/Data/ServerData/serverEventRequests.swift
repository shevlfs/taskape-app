//
//  serverEventRequests.swift
//  taskape
//
//  Created by shevlfs on 3/27/25.
//

import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import SwiftUI

// MARK: - Event Fetch Functions

func fetchEvents(userId: String, includeExpired: Bool = false, limit: Int = 20) async -> [taskapeEvent]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token
        ]

        // Create URL with query parameters
        var urlComponents = URLComponents(string: "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/events")
        urlComponents?.queryItems = [
            URLQueryItem(name: "include_expired", value: includeExpired ? "true" : "false"),
            URLQueryItem(name: "limit", value: "\(limit)")
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
            // Print the raw response data
            if let data = response.data {
                // print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")

                // Try decoding manually to see detailed error
                do {
                    let decoded = try JSONDecoder().decode(GetEventsResponse.self, from: data)
                  
                } catch {
                    print("Decode error: \(error)")

                    // For CodingKeys mismatch errors, print more details
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Missing key: \(key), path: \(context.codingPath)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch: expected \(type), path: \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("Value not found: expected \(type), path: \(context.codingPath)")
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
        case .success(let response):
            if response.success {
                let events = response.events.map { convertToLocalEvent($0) }
                return events
            } else {
                print("failed to fetch events: \(response.message ?? "unknown error")")
                return nil
            }
        case .failure(let error):
            print("failed to fetch events: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Event Like Functions

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
                "Authorization": token
            ]
        )
        .validate()
        .serializingDecodable(LikeEventResponse.self)
        .response

        switch result.result {
        case .success(let response):
            return response.success
        case .failure(let error):
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

    // For DELETE requests with query parameters
    var urlComponents = URLComponents(string: "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/like")
    urlComponents?.queryItems = [
        URLQueryItem(name: "user_id", value: userId)
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return false
    }

    let headers: HTTPHeaders = [
        "Authorization": token
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
        case .success(let response):
            return response.success
        case .failure(let error):
            print("failed to unlike event: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Event Comments Functions

func fetchEventComments(eventId: String, limit: Int = 20, offset: Int = 0) async -> [EventComment]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }

    // Create URL with query parameters
    var urlComponents = URLComponents(string: "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/comments")
    urlComponents?.queryItems = [
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "offset", value: "\(offset)")
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return nil
    }

    let headers: HTTPHeaders = [
        "Authorization": token
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
        case .success(let response):
            if response.success {
                let comments = response.comments.map { convertToLocalComment($0) }
                return comments
            } else {
                print("failed to fetch comments: \(response.message ?? "unknown error")")
                return nil
            }
        case .failure(let error):
            print("failed to fetch comments: \(error.localizedDescription)")
            return nil
        }
    }
}

// Define a proper response type for the add comment API
struct AddEventCommentResponse: Codable {
    let success: Bool
    let comment: EventCommentResponse
    let message: String?
}

func addEventComment(eventId: String, userId: String, content: String) async -> EventComment? {
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
            encoder: JSONParameterEncoder.default, headers: [
                "Authorization": token
            ]
        )
        .validate()
        .serializingDecodable(AddEventCommentResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                return convertToLocalComment(response.comment)
            } else {
                print("failed to add comment: \(response.message ?? "unknown error")")
                return nil
            }
        case .failure(let error):
            print("failed to add comment: \(error.localizedDescription)")
            return nil
        }
    }
}

struct DeleteEventCommentResponse: Codable {
    let success: Bool
    let message: String?
}

func deleteEventComment(eventId: String, commentId: String, userId: String) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }

    // For DELETE requests with query parameters
    var urlComponents = URLComponents(string: "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/events/\(eventId)/comments/\(commentId)")
    urlComponents?.queryItems = [
        URLQueryItem(name: "user_id", value: userId)
    ]

    guard let url = urlComponents?.url else {
        print("invalid url components")
        return false
    }

    let headers: HTTPHeaders = [
        "Authorization": token
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
        case .success(let response):
            return response.success
        case .failure(let error):
            print("failed to delete comment: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Task Confirmation Function

func confirmTaskCompletion(taskId: String, confirmerId: String, isConfirmed: Bool) async -> Bool {
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
            encoder: JSONParameterEncoder.default, headers: ["Authorization": token]
        )
        .validate()
        .serializingDecodable(ConfirmTaskCompletionResponse.self)
        .response

        switch result.result {
        case .success(let response):
            return response.success
        case .failure(let error):
            print("failed to confirm task completion: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Helper Conversion Functions

// Helper function to convert an EventResponse to a local taskapeEvent
func convertToLocalEvent(_ event: EventResponse) -> taskapeEvent {
    let dateFormatter = ISO8601DateFormatter()

    let createdAt = dateFormatter.date(from: event.created_at) ?? Date()

    var expiresAt: Date? = nil
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

// Helper function to convert an EventCommentResponse to a local EventComment
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

// Function to load related tasks for events
func loadRelatedTasksForEvents(events: [taskapeEvent], modelContext: ModelContext) async {
    // Get all task IDs from all events
    var allTaskIds: Set<String> = Set<String>()
    for event in events {
        allTaskIds.formUnion(event.taskIds)
    }

    // Skip if no task IDs found
    if allTaskIds.isEmpty {
        return
    }

    // Get the current user ID for the requester_id
    let requesterId = UserManager.shared.currentUserId

    // Fetch tasks for these IDs
    for taskId in allTaskIds {
        // If we already have this task in memory, skip fetching
        let taskDescriptor = FetchDescriptor<taskapeTask>(
            predicate: #Predicate<taskapeTask> { task in
                task.id == taskId
            }
        )

        do {
            let existingTasks = try modelContext.fetch(taskDescriptor)
            if !existingTasks.isEmpty {
                // Update the task relationship
                let task = existingTasks[0]
                for event in events where event.taskIds.contains(taskId) {
                    if !event.relatedTasks.contains(where: { $0.id == task.id }) {
                        event.relatedTasks.append(task)
                    }
                }
                continue
            }
        } catch {
            print("error checking for existing task: \(error)")
        }

        // Fetch the individual task
        guard let task = await fetchTask(taskId: taskId, requesterId: requesterId) else {
            continue
        }

        // Insert the task into the context
        modelContext.insert(task)

        // Associate task with related events
        for event in events where event.taskIds.contains(taskId) {
            if !event.relatedTasks.contains(where: { $0.id == task.id }) {
                event.relatedTasks.append(task)
            }
        }
    }

    // Save the context
    do {
        try modelContext.save()
    } catch {
        print("error saving context after loading related tasks: \(error)")
    }
}

