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

func phoneNumberIsVerified(
    phoneNumber: String, country_code: String, code: String
) async -> Bool {
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

        switch result.result {
        case .success(let response):
            if !response.authToken.isEmpty {
                UserDefaults.standard.set(
                    response.authToken, forKey: "auth_token")
                return true
            }
            return false

        case .failure(let error):
            print(
                "Failed to verify phone number: \(error.localizedDescription)")
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
