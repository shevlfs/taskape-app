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
            } else {
                MainNavigationView().modelContext(modelContext)
            }
        }
        .onAppear {
            Task {
                if let userId = UserDefaults.standard.string(forKey: "user_id") {
                    print("fetching user")
                    let user = await fetchUser(userId: userId)

                    print("fetching tasks")
                    let tasks = await fetchTasks(userId: userId)
                    await MainActor.run {
                        if let user = user {
                            print(user.id)
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
}
