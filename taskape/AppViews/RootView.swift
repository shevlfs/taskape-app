//
//  RootView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import SwiftUI

struct RootView: View {

    @State private var isLoggedIn: Bool = false

    @State private var phoneExistsInDatabase: Bool = false

    @State private var isLoading: Bool = true

    @State private var userAlreadyExists: Bool = false

    func tokenIsActive() async -> Bool {
        var token = UserDefaults.standard.string(forKey: "authToken")
        if token != nil {
            if await validateToken(token: token!) {
                print("token validate success")
                phoneExistsInDatabase = true
                return true
            }
            print("validate token failed")
            let refreshToken = UserDefaults.standard.string(
                forKey: "refreshToken")!
            let phone = UserDefaults.standard.string(forKey: "phone")!
            if await refreshTokenRequest(
                token: token!, refreshToken: refreshToken, phone: phone)
            {
                print("refresh success")
                phoneExistsInDatabase = true
                return true
            }
            print("refresh failed")

        }
        return false
    }

    var body: some View {
        Group {
            if isLoading {
                EmptyView()
            } else {
                if !isLoggedIn {
                    AuthenticationView(
                        phoneNumberExistsInDatabase: $phoneExistsInDatabase,
                        userAlreadyExists: $userAlreadyExists
                    ).onChange(
                        of: userAlreadyExists
                    ) {
                        isLoggedIn = true
                    }
                } else {
                    MainView()
                }
            }
        }.onAppear {
            Task {
                await serverHandShake()
                isLoggedIn =
                    await tokenIsActive()
                    && UserDefaults.standard.bool(
                        forKey: "profileExists")
                isLoading = false
            }
        }
    }
}

#Preview {
    RootView()
}
