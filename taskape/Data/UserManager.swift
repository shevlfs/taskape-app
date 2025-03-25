//
//  UserManager.swift
//  taskape
//
//  Created by shevlfs on 3/26/25.
//

import Foundation
import SwiftData
import SwiftUI

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUserId: String =
        UserDefaults.standard.string(forKey: "user_id") ?? ""

    // Fetch the current user from the ModelContext using the ID
    func getCurrentUser(context: ModelContext) -> taskapeUser? {
        guard !currentUserId.isEmpty else { return nil }

        let predicate = #Predicate<taskapeUser> {
            user in user.id == currentUserId
        }

        let descriptor = FetchDescriptor<taskapeUser>(predicate: predicate)

        do {
            let users = try context.fetch(descriptor)
            return users.first
        } catch {
            print("Error fetching current user: \(error)")
            return nil
        }
    }

    // Check if a user is the current user
    func isCurrentUser(userId: String) -> Bool {
        return userId == currentUserId
    }

    // Update the current user ID (e.g., after login)
    func setCurrentUser(userId: String) {
        currentUserId = userId
        UserDefaults.standard.set(userId, forKey: "user_id")
    }
}
