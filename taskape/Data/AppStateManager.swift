






import Foundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {

        let profileExists = UserDefaults.standard.bool(forKey: "profileExists")
        let hasToken = UserDefaults.standard.string(forKey: "authToken") != nil
        let hasUserId = !UserManager.shared.currentUserId.isEmpty

        self.isLoggedIn = profileExists && hasToken && hasUserId

        print("AppStateManager initialized with isLoggedIn: \(self.isLoggedIn)")
        print("- profileExists: \(profileExists)")
        print("- hasToken: \(hasToken)")
        print("- hasUserId: \(hasUserId)")
    }

    func logout() {

        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.set(false, forKey: "profileExists")


        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "handle")
        UserDefaults.standard.removeObject(forKey: "bio")
        UserDefaults.standard.removeObject(forKey: "color")
        UserDefaults.standard.removeObject(forKey: "profile_picture_url")
        UserDefaults.standard.removeObject(forKey: "phone")
        UserDefaults.standard.set(false, forKey: "numberIsRegistered")
        UserDefaults.standard.removeObject(forKey: "userPhoneNumber")


        UserManager.shared.setCurrentUser(userId: "")


        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }

    func login() {

        if let userId = UserDefaults.standard.string(forKey: "user_id"), !userId.isEmpty {
            UserManager.shared.setCurrentUser(userId: userId)
        }

        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
}
