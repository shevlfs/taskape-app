//
//  dto.swift
//  taskape
//
//  Created by shevlfs on 2/14/25.
//

struct VerificationResponse: Codable {
    let authToken: String
    let refreshToken: String
    let profileExists: Bool
}

struct TokenRefreshResponse: Codable {
    let authToken: String
    let refreshToken: String
}

struct RegisterNewProfileRequest: Codable {
    let handle: String
    let bio: String
    let color: String
    let profile_picture: String
    let phone: String
    let token: String
}

struct RegisterNewProfileResponse: Codable {
    let success: Bool
    let id: Int
}
