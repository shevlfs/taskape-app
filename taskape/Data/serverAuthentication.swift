//
//  serverAuthentication.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

import Alamofire
import Foundation
import SwiftData

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

func sendVerificationCode(phoneNumber: String, country_code: String) {
    var user_phone = "\(country_code)\(phoneNumber)"
    user_phone.replace(" ", with: "")
    debugPrint("verifyPhoneNumber called, \(user_phone)")
    return
}

func phoneNumberIsVerified(
    phoneNumber: String, country_code: String, code: String
) -> Bool {
    return code == "111111"
}

func addUserHandleSuccess(handle: String) -> Bool {
    let defaults = UserDefaults.standard
    let phoneNumberKey = "userPhoneNumber"

    let phone_number = defaults.string(forKey: phoneNumberKey)
    debugPrint("phone number is \(phone_number)")
    return true

}
