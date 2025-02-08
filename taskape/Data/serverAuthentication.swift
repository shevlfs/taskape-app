//
//  serverAuthentication.swift
//  taskape
//
//  Created by shevlfs on 1/27/25.
//

import Foundation
import GRPCCore
import GRPCInProcessTransport
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import SwiftData

func serverHandShake() async -> Bool {
    var name: String = "app"
    try? await withGRPCClient(
        transport: .http2NIOPosix(
            target: .ipv4(host: "127.0.0.1", port: 50051),
            transportSecurity: .plaintext
        )
    ) { client in
        let greeter = Hello_Greeter.Client(wrapping: client)
        let reply = try await greeter.sayHello(.with { $0.name = name })
        print(reply.message)
    }
    return true
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
