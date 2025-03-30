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
    @State private var currentUser: taskapeUser?
    @State private var showLogoutConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                
                
                
                if let user = currentUser {
                    // User profile section
                    VStack(alignment: .center, spacing: 12) {
                        Text("logged in as")
                            .font(.pathway(16))
                            .foregroundColor(.secondary)
                        
                        Text("\(user.handle)")
                            .font(.pathwayBlack(22))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
                
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
                .alert("logout confirmation", isPresented: $showLogoutConfirmation)
                {
                    Button("cancel", role: .cancel) {}
                    Button("logout", role: .destructive) {
                        performLogout()
                    }
                } message: {
                    Text("are you sure you want to logout?")
                }
                Spacer()
            }.frame(maxWidth: .infinity)
        }
        .onAppear {
            currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)
        }
    }

    func performLogout() {
        // Clear user data from SwiftData
        do {
            // Clear the UserManager current user
            UserManager.shared.setCurrentUser(userId: "")

            // Clear all data from SwiftData
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
            // Still attempt to logout even if there was an error clearing data
            appState.logout()
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config)

        // Create user directly in the container
        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio: "i am shevlfs",
            profileImage: "https://example.com/profile.jpg",
            profileColor: "blue"
        )

        // Manually insert the user and set it as the current user
        container.mainContext.insert(user)
        try container.mainContext.save()

        UserManager.shared.setCurrentUser(userId: user.id)

        return SettingsView()
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("failed to create preview: \(error.localizedDescription)")
    }
}
