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
    @State private var loadingError: String? = nil

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading your profile...")
            } else if let error = loadingError {
                VStack {
                    Text(error.lowercased()).font(.pathway(26))
                        .padding()
                        .multilineTextAlignment(.center)

                    Button("return to Login") {
                        appState.logout()
                    }.font(.pathway(20))
                    .padding()
                    .background(Color.taskapeOrange)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .padding(.top, 20)
                }
            } else {
                MainNavigationView()
                    .modelContext(modelContext)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            Task {
                let userId = UserManager.shared.currentUserId
                if !userId.isEmpty {
                    print("Loading profile for user ID: \(userId)")

                    // Try to fetch the user from the database first
                    let existingUser = UserManager.shared.getCurrentUser(context: modelContext)

                    if existingUser != nil {
                        print("User found in local database, no need to fetch from server")
                        await MainActor.run {
                            isLoading = false
                        }
                        return
                    }

                    // Fetch the user from the server
                    let user = await fetchUser(userId: userId)

                    // Fetch tasks for the user
                    let tasks = await fetchTasks(userId: userId)

                    await MainActor.run {
                        if let user = user {
                            print("User fetched from server: \(user.id)")
                            insertUser(user: user, context: modelContext)

                            if let tasks = tasks {
                                syncUserTasks(
                                    userId: userId,
                                    remoteTasks: tasks,
                                    modelContext: modelContext
                                )
                            }

                            isLoading = false
                        } else {
                            loadingError = "Could not load your profile. Please try again."
                            isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        loadingError = "No user ID found. Please log in again."
                        isLoading = false
                    }
                }
            }
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
