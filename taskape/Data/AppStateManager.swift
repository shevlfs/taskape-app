//
//  AppStateManager.swift
//  taskape
//
//  Created by shevlfs on 3/19/25.
//

import Foundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        // Initialize based on stored values
        self.isLoggedIn =
            UserDefaults.standard.bool(forKey: "profileExists")
            && UserDefaults.standard.string(forKey: "authToken") != nil
    }

    func logout() {
        // Clear authentication data
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.set(false, forKey: "profileExists")

        // Clear user creation flow state
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "handle")
        UserDefaults.standard.removeObject(forKey: "bio")
        UserDefaults.standard.removeObject(forKey: "color")
        UserDefaults.standard.removeObject(forKey: "profile_picture_url")
        UserDefaults.standard.removeObject(forKey: "phone")
        UserDefaults.standard.set(false, forKey: "numberIsRegistered")
        UserDefaults.standard.removeObject(forKey: "userPhoneNumber")

        // Update the published state
        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }

    func login() {
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
}
