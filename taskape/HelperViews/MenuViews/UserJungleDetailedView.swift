import SwiftData
import SwiftUI

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [taskapeUser]

    @State private var isRefreshing: Bool = false
    @State private var showCompletedTasks: Bool = true

    var body: some View {
        VStack {
            if let currentUser = users.first {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Your Jungle")
                            .font(.pathwayBlack(24))
                        Spacer()
                        Menu {
                            Button(action: {
                                showCompletedTasks.toggle()
                            }) {
                                Label(
                                    showCompletedTasks ? "Hide Completed Tasks" : "Show Completed Tasks",
                                    systemImage: showCompletedTasks ? "eye.slash" : "eye"
                                )
                            }

                            Button(action: {
                                refreshTasks()
                            }) {
                                Label("Refresh Tasks", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 24))
                        }
                    }
                    .padding([.horizontal, .top])

                    if currentUser.tasks.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Text("No tasks here yet")
                                .font(.pathway(18))
                            Text("Add a new task to start growing your jungle!")
                                .font(.pathwayItalic(16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Filter tasks based on completion status if needed
                                ForEach(currentUser.tasks.filter { showCompletedTasks || !$0.completion.isCompleted }) { task in
                                    taskCard(task: .constant(task))
                                }
                            }
                            .padding()
                        }
                    }
                }
                .overlay(
                    Group {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.2))
                        }
                    }
                )
            } else {
                Text("No user profile found")
                    .font(.pathway(18))
                    .padding()
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add new task
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            refreshTasks()
        }
    }

    private func refreshTasks() {
        guard let userId = users.first?.id else { return }

        isRefreshing = true

        Task {
            await syncUserTasks(userId: userId, modelContext: modelContext)

            await MainActor.run {
                isRefreshing = false
            }
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
            profileImage: "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
            profileColor: "blue"
        )

        container.mainContext.insert(user)

        // Add some sample tasks
        for i in 1...5 {
            let task = taskapeTask(
                id: UUID().uuidString,
                user_id: user.id,
                name: "Task \(i)",
                taskDescription: "This is a description for task \(i)",
                author: "shevlfs",
                privacy: "private"
            )

            // Make some tasks completed
            if i % 2 == 0 {
                task.markAsCompleted()
            }

            container.mainContext.insert(task)
            user.tasks.append(task)
        }

        try container.mainContext.save()

        return NavigationStack {
            UserJungleDetailedView()
                .modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
