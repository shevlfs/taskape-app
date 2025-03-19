//
//  RootView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import SwiftDotenv
import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppStateManager()
    @State private var phoneExistsInDatabase: Bool = false
    @State private var isLoading: Bool = true
    @State private var userAlreadyExists: Bool = false

    func tokenIsActive() async -> Bool {
        if let path = Bundle.main.path(
            forResource: ".env", ofType: nil)
        {
            print("loading dotenv")
            try! Dotenv.configure(atPath: path)
        } else {
            print("dotenv is gone")
        }
        let token = UserDefaults.standard.string(forKey: "authToken")
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
                ProgressView("Loading...")
                    .onAppear {
                        loadEnvironment()
                    }
            } else {
                if !appState.isLoggedIn {
                    AuthenticationView(
                        phoneNumberExistsInDatabase: $phoneExistsInDatabase,
                        userAlreadyExists: $userAlreadyExists
                    )
                    .statusBarHidden(true)
                    .onAppear {
                        loadEnvironment()
                    }
                    .onChange(of: userAlreadyExists) {
                        appState.login()
                    }
                } else {
                    MainRootView()
                        .onAppear {
                            loadEnvironment()
                        }
                        .environmentObject(appState)
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            Task {
                let tokenActive = await tokenIsActive()
                let profileExists = UserDefaults.standard.bool(forKey: "profileExists")

                await MainActor.run {
                    if tokenActive && profileExists {
                        appState.isLoggedIn = true
                    } else {
                        appState.isLoggedIn = false
                    }
                    isLoading = false
                }
            }
        }
    }

    private func loadEnvironment() {
        if let path = Bundle.main.path(forResource: ".env", ofType: nil) {
            print("loading dotenv")
            try! Dotenv.configure(atPath: path)
        } else {
            print("dotenv is gone")
        }
    }
}

#Preview {
    RootView()
}
