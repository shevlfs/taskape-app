//
//  serverAuthentication.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

import Alamofire
import Foundation
import SwiftData
import SwiftUI
import SwiftDotenv

func serverHandShake() async -> Bool {
    do {
        let result = await AF.request("\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/ping")
            .validate()
            .serializingData()
            .response

        if let error = result.error {
            print("Error: \(error.localizedDescription)")
            return false
        }

        if let data = result.data {
            print(
                "Ping response: \(String(data: data, encoding: .utf8) ?? "Invalid data")"
            )
        }
        return true
    }
}

func sendVerificationCode(phoneNumber: String, country_code: String) async {
    var user_phone = "\(country_code)\(phoneNumber)"
    user_phone.replace(" ", with: "")

    do {
        let parameters: [String: Any] = [
            "phone": user_phone
        ]
        _ = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/sendVerificationCode",
            method: .post, parameters: parameters,
            encoding: JSONEncoding.default
        ).validate().serializingData().response
    }
    return
}

enum verificationResult {
    case success
    case userexists
    case failed
}

func phoneNumberIsVerified(
    phoneNumber: String, country_code: String, code: String
) async -> verificationResult {
    var user_phone = "\(country_code)\(phoneNumber)"
    user_phone.replace(" ", with: "")

    do {
        let parameters: [String: Any] = [
            "phone": user_phone,
            "code": code,
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/checkVerificationCode",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).validate().serializingDecodable(VerificationResponse.self).response


        switch result.result {
        case .success(let response):
            if !response.authToken.isEmpty {
                UserDefaults.standard.set(
                    response.authToken, forKey: "authToken")
                UserDefaults.standard.set(
                    response.refreshToken, forKey: "refreshToken")
                UserDefaults.standard.set(user_phone, forKey: "phone")

                if response.profileExists {
                    let userId = String(response.userId)
                    UserDefaults.standard.set(userId, forKey: "user_id")
                    UserManager.shared.setCurrentUser(userId: userId)
                    return .userexists
                }
                return .success
            }
            return .failed
        case .failure(let error):
            print(
                "Failed to verify phone number: \(error.localizedDescription)")
            return .failed
        }
    }
}

func validateToken(token: String) async -> Bool {
    do {

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/validateToken",
            method: .post,
            parameters: [
                "token": token
            ],
            encoding: JSONEncoding.default
        ).serializingString().response

        switch result.response?.statusCode {
        case 200:
            return true

        case 401:
            return false

        default:
            print(
                "unexpected status code while validating token \( String(describing: result.response?.statusCode))"
            )
            return false
        }
    }
}

func refreshTokenRequest(token: String, refreshToken: String, phone: String)
    async
    -> Bool
{
    do {
        let parameters: [String: Any] = [
            "token": token,
            "refresh_token": refreshToken,
            "phone": phone,
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/refreshToken",
            method: .post, parameters: parameters,
            encoding: JSONEncoding.default
        ).validate().serializingDecodable(
            TokenRefreshResponse.self
        ).response

        switch result.result {
        case .success(let response):
            if !response.authToken.isEmpty {
                UserDefaults.standard.set(
                    response.authToken, forKey: "authToken")
                UserDefaults.standard.set(
                    response.refreshToken, forKey: "refreshToken")
                return true
            }
            return false

        case .failure(let error):
            print(
                "failed to refresh token \(error.localizedDescription)")
            return false
        }
    }
}

func registerProfile(
    handle: String,
    bio: String,
    color: String,
    profilePictureURL: String,
    phone: String
) async throws -> RegisterNewProfileResponse {
    let request = RegisterNewProfileRequest(
        handle: handle,
        bio: bio,
        color: color,
        profile_picture: profilePictureURL,
        phone: phone,
        token: UserDefaults.standard.string(forKey: "authToken") ?? ""
    )
    return try await withCheckedThrowingContinuation { continuation in
        AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/registerNewProfile",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .responseDecodable(of: RegisterNewProfileResponse.self) { response in
            switch response.result {
            case .success(let registerResponse):
                continuation.resume(returning: registerResponse)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

func checkHandleAvailability(handle: String) async -> Bool {
    do {
        guard !handle.isEmpty else {
            return false
        }
        let parameters: [String: Any] = [
            "handle": handle,
            "token": UserDefaults.standard.string(forKey: "authToken") ?? "",
        ]
        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/checkHandleAvailability",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .serializingDecodable(CheckHandleAvailabilityResponse.self)
        .response
        switch result.result {
        case .success(let response):
            print("Handle availability: \(response.available)")
            return response.available
        case .failure(let error):
            print(
                "Failed to check handle availability: \(error.localizedDescription)"
            )
            return false
        }
    }
}
