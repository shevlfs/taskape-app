//
//  serverAuthentication.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

import SwiftData
import SwiftProtobuf

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
