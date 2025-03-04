//
//  MainNavigationView.swift
//  taskape
//
//  Created by shevlfs on 2/5/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct MainNavigationView: View {
    @State private var isLoading = true

    @Environment(\.modelContext) private var modelContext
    @Query var currentUser: [taskapeUser]

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading your profile...")
            } else if currentUser.isEmpty {
                Text("Could not load user profile. Please try again.")
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                MainView().modelContext(modelContext)
            }
        }
        .onAppear {
            Task {
                if let userId = UserDefaults.standard.string(forKey: "user_id")
                {
                    print("fetching user")
                    _ = await fetchAndInsertUser(
                        userId: userId, context: modelContext)
                }
                await MainActor.run {
                    isLoading = false
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
