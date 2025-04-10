

import CachedAsyncImage
import SwiftData
import SwiftUI

struct MainRootView: View {
    @State private var isLoading = true
    @State private var loadingError: String? = nil

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager

    @State var fullyLoaded = false

    @State var animationAppeared: Bool = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            if isLoading {
                AnimatedLogoView().opacity(isVisible ? 1.0 : 0.0).onAppear {
                    withAnimation(.easeIn(duration: 0.5)) {
                        isVisible = true
                    }
                }
            }

            VStack {
                if !isLoading {
                    if let error = loadingError {
                        VStack {
                            Text(error.lowercased()).font(.pathway(26))
                                .padding()
                                .multilineTextAlignment(.center)

                            Button("return to login") {
                                appState.logout()
                            }.font(.pathway(20))
                                .padding()
                                .background(Color.taskapeOrange)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                                .padding(.top, 20)
                        }
                    } else {
                        MainNavigationView(fullyLoaded: $fullyLoaded)
                            .modelContext(modelContext)
                            .environmentObject(appState)
                    }
                }
            }
        }
        .onAppear {
            Task {
                if !appState.isLoggedIn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(
                            .spring(response: 1, dampingFraction: 0.6)
                        ) {
                            isLoading = false
                            loadingError =
                                "couldn't load your profile\nplease login again"
                        }
                    }
                }
                let userId = UserManager.shared.currentUserId
                if !userId.isEmpty {
                    print("Loading profile for user ID: \(userId)")

                    let existingUser = UserManager.shared.getCurrentUser(
                        context: modelContext)

                    loadData()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(
                            .spring(response: 1, dampingFraction: 0.6)
                        ) {
                            isLoading = false
                        }
                    }

                    let user = await fetchUser(userId: userId)

                    let tasks = await fetchTasks(userId: userId)

                    await MainActor.run {
                        if let user {
                            print("User fetched from server: \(user.id)")
                            insertUser(user: user, context: modelContext)

                            if let tasks {
                                syncUserTasks(
                                    userId: userId,
                                    remoteTasks: tasks,
                                    modelContext: modelContext
                                )

                                updateWidgetWithTasks(
                                    userId: userId, modelContext: modelContext
                                )
                            }

                            loadData()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(
                                    .spring(response: 1, dampingFraction: 0.6)
                                ) {
                                    isLoading = false
                                }
                            }
                        } else {
                            loadingError =
                                "could not load your profile.\nplease try again."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(
                                    .spring(response: 1, dampingFraction: 0.6)
                                ) {
                                    isLoading = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func loadData() {
        _ = UserManager.shared.getCurrentUser(
            context: modelContext)
        Task {
            if let remoteTasks = await UserManager.shared
                .fetchCurrentUserTasks()
            {
                await MainActor.run {
                    syncUserTasks(
                        userId: UserManager.shared.currentUserId,
                        remoteTasks: remoteTasks,
                        modelContext: modelContext
                    )
                    updateWidgetWithTasks(
                        userId: UserManager.shared.currentUserId,
                        modelContext: modelContext
                    )
                }
            }
        }
    }
}

#Preview {
    var user = taskapeUser(
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
