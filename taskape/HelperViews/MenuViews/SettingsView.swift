//
//  SettingsView.swift
//  taskape
//
//  Created by shevlfs on 3/5/25.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @Query var users: [taskapeUser]
    @State private var showLogoutConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            Text("settings")
                .font(.pathwayBold(24))
                .padding(.top)

            Spacer()

            if let user = users.first {
                // User profile section
                VStack(alignment: .center, spacing: 12) {
                    Text("Logged in as")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)

                    Text("@\(user.handle)")
                        .font(.pathwayBlack(22))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }

            Spacer()

            // Logout button at the bottom
            Button(action: {
                showLogoutConfirmation = true
            }) {
                Text("logout")
                    .font(.pathway(18))
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red.opacity(0.8))
                    )
            }
            .padding(.bottom, 32)
            .alert("Logout Confirmation", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout from your account?")
            }
        }
    }

    func performLogout() {
        // Clear user data from SwiftData
        do {
            let userDescriptor = FetchDescriptor<taskapeUser>()
            let taskDescriptor = FetchDescriptor<taskapeTask>()

            let existingUsers = try modelContext.fetch(userDescriptor)
            let existingTasks = try modelContext.fetch(taskDescriptor)

            for user in existingUsers {
                modelContext.delete(user)
            }

            for task in existingTasks {
                modelContext.delete(task)
            }

            try modelContext.save()

            print("User data cleared for logout")

            // Use the app state manager to logout
            appState.logout()

        } catch {
            print("Error clearing user data during logout: \(error)")
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config)

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio: "i am shevlfs",
            profileImage:
                "https://example.com/profile.jpg",
            profileColor: "blue"
        )

        container.mainContext.insert(user)
        try container.mainContext.save()

        return SettingsView()
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
