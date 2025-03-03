//
//  serverGetRequests.swift
//  taskape
//
//  Created by shevlfs on 2/23/25.
//

import Alamofire
import Foundation
import SwiftUI

func getUserById(userId: String) async -> taskapeUser? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    do {
        let headers: HTTPHeaders = [
            "Authorization": token
        ]

        let result = await AF.request(
            "http://localhost:8080/users/\(userId)",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(UserResponse.self)
        .response

        switch result.result {
        case .success(let response):
            if response.success {
                let user = taskapeUser(
                    id: response.id,
                    handle: response.handle,
                    bio: response.bio, profileImage: response.profile_picture,
                    profileColor: response.color
                )
                return user
            } else {
                print("Failed to fetch user: \(response.error ?? "Unknown error")")
                return nil
            }
        case .failure(let error):
            print("Failed to fetch user: \(error.localizedDescription)")
            return nil
        }
    }
}
