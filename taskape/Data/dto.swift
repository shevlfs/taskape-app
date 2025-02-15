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
