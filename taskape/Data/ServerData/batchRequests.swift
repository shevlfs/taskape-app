//
//  GetUsersBatchRequest.swift
//  taskape
//
//  Created by shevlfs on 4/2/25.
//


//
//  batchRequests.swift
//  taskape
//
//  Created on 4/1/25.
//

import Alamofire
import Foundation
import SwiftData
import SwiftDotenv
import SwiftUI

// MARK: - Get Users Batch

struct GetUsersBatchRequest: Codable {
    let user_ids: [String]
    let token: String
}

struct GetUsersBatchResponse: Codable {
    let success: Bool
    let users: [UserResponse]
    let message: String?
}

// MARK: - Get Users Tasks Batch

struct GetUsersTasksBatchRequest: Codable {
    let user_ids: [String]
    let requester_id: String
    let token: String
}

struct GetUsersTasksBatchResponse: Codable {
    let success: Bool
    let user_tasks: [String: [TaskResponse]]
    let message: String?
}

// MARK: - Edit User Profile

struct EditUserProfileRequest: Codable {
    let user_id: String
    let handle: String
    let bio: String
    let color: String
    let profile_picture: String
    let token: String
}

struct EditUserProfileResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - API Functions

func getUsersBatch(userIds: [String]) async -> [taskapeUser]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }
    
    // Create request payload
    let request = GetUsersBatchRequest(
        user_ids: userIds,
        token: token
    )
    
    do {
        // Make the API request
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/getUsersBatch",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(GetUsersBatchResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                // Convert API response to local taskapeUser objects
                let users = response.users.map { userResponse in
                    taskapeUser(
                        id: userResponse.id,
                        handle: userResponse.handle,
                        bio: userResponse.bio,
                        profileImage: userResponse.profile_picture,
                        profileColor: userResponse.color
                    )
                }
                return users
            } else {
                print("failed to fetch users batch: \(response.message ?? "unknown error")")
                return nil
            }
        case .failure(let error):
            print("failed to fetch users batch: \(error.localizedDescription)")
            return nil
        }
    }
}

func getUsersTasksBatch(userIds: [String], requesterId: String) async -> [String: [taskapeTask]]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return nil
    }
    
    // Create request payload
    let request = GetUsersTasksBatchRequest(
        user_ids: userIds,
        requester_id: requesterId,
        token: token
    )
    
    do {
        // Make the API request
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/getUsersTasksBatch",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(GetUsersTasksBatchResponse.self)
        .response
        
        switch result.result {
        case .success(let response):
            if response.success {
                // Convert API response to local taskapeTask objects
                var userTasks: [String: [taskapeTask]] = [:]
                
                for (userId, tasks) in response.user_tasks {
                    let convertedTasks = tasks.map { convertToLocalTask($0) }
                    userTasks[userId] = convertedTasks
                }
                
                return userTasks
            } else {
                print("failed to fetch users tasks batch: \(response.message ?? "unknown error")")
                return nil
            }
        case .failure(let error):
            print("failed to fetch users tasks batch: \(error.localizedDescription)")
            return nil
        }
    }
}

func editUserProfile(userId: String, handle: String? = nil, bio: String? = nil, color: String? = nil, profilePictureURL: String? = nil) async -> Bool {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("no auth token found")
        return false
    }
    
    // Create request payload with only fields that are provided
    var request = EditUserProfileRequest(
        user_id: userId,
        handle: handle ?? "",
        bio: bio ?? "",
        color: color ?? "",
        profile_picture: profilePictureURL ?? "",
        token: token
    )
    
    do {
        // Make the API request
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/editUserProfile",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .serializingDecodable(EditUserProfileResponse.self)
        .response
        
        switch result.result {
        case .success(let response):
            return response.success
        case .failure(let error):
            print("failed to edit user profile: \(error.localizedDescription)")
            return false
        }
    }
}