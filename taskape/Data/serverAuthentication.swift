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

func serverHandShake() async -> Bool {
    do {
        let result = await AF.request("http://localhost:8080/ping")
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
            "http://localhost:8080/sendVerificationCode",
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
            "http://localhost:8080/checkVerificationCode",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).validate().serializingDecodable(VerificationResponse.self).response

        print(result.result)

        switch result.result {
        case .success(let response):
            if !response.authToken.isEmpty {
                UserDefaults.standard.set(
                    response.authToken, forKey: "authToken")
                UserDefaults.standard.set(
                    response.refreshToken, forKey: "refreshToken")

                UserDefaults.standard.set(phoneNumber, forKey: "phone")

                if response.profileExists {
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
            "http://localhost:8080/validateToken",
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
            "refreshToken": refreshToken,
            "phone": phone,
        ]

        let result = await AF.request(
            "http://localhost:8080/refreshToken",
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

func addUserHandleSuccess(handle: String) -> Bool {
    return true
}

func addUserBioSuccess(bio: String) -> Bool {
    return true
}

func addUserColorSuccess(color: String) -> Bool {
    return true
}

func addUserPFPSuccess(image: UIImage?) -> Bool {
    return true
}
