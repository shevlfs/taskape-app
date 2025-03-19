//
//  MainNavigationView.swift
//  taskape
//
//  Created by shevlfs on 2/5/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct MainRootView: View {
    @State private var isLoading = true

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @Query var currentUser: [taskapeUser]
    @Query var tasks: [taskapeTask]

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading your profile...")
            } else if currentUser.isEmpty {
                Text("Could not load user profile. Please try again.")
                    .padding()
                    .multilineTextAlignment(.center)

                Button("Return to Login") {
                    appState.logout()
                }
                .padding()
                .background(Color.taskapeOrange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.top, 20)
            } else {
                MainNavigationView()
                    .modelContext(modelContext)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            Task {
                if let userId = UserDefaults.standard.string(forKey: "user_id") {
                    print("fetching user with ID: \(userId)")

                    // Clear previous user data
                    clearExistingUserData()

                    // Fetch the current user
                    let user = await fetchUser(userId: userId)

                    // Fetch tasks for the user
                    let tasks = await fetchTasks(userId: userId)

                    await MainActor.run {
                        if let user = user {
                            print("User fetched: \(user.id)")
                            // Insert the new user as the first and only user
                            insertUser(user: user, context: modelContext)
                        }

                        if let tasks = tasks {
                            syncUserTasks(
                                userId: userId,
                                remoteTasks: tasks,
                                modelContext: modelContext
                            )
                        }

                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        }
    }

    // Function to clear existing users from the model context
    private func clearExistingUserData() {
        do {
            // Fetch all existing users
            let userDescriptor = FetchDescriptor<taskapeUser>()
            let existingUsers = try modelContext.fetch(userDescriptor)

            print("Clearing \(existingUsers.count) existing users")

            // Delete each user
            for user in existingUsers {
                modelContext.delete(user)
            }

            // Fetch all existing tasks
            let taskDescriptor = FetchDescriptor<taskapeTask>()
            let existingTasks = try modelContext.fetch(taskDescriptor)

            print("Clearing \(existingTasks.count) existing tasks")

            // Delete each task
            for task in existingTasks {
                modelContext.delete(task)
            }

            try modelContext.save()
            print("Successfully cleared existing user data")
        } catch {
            print("Error clearing existing user data: \(error)")
        }
    }
}

#Preview {
    var user: taskapeUser = taskapeUser(
        id: UUID().uuidString,
        handle: "shevlfs",
        bio: "i am shevlfs",
        profileImage:
            "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
        profileColor: "blue"
    )

    return MainRootView()
        .environmentObject(AppStateManager())
}
