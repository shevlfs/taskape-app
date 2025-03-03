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
    let userId: Int64
}

struct TokenRefreshResponse: Codable {
    let authToken: String
    let refreshToken: String
}

struct UserResponse: Codable {
    let success: Bool
    let id: String
    let handle: String
    let bio: String
    let profile_picture: String
    let color: String
    let error: String?
}

struct CheckHandleAvailabilityResponse: Codable {
    let available: Bool
    let message: String?
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
