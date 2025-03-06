import SwiftData
import SwiftUI

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var users: [taskapeUser]

    @State private var isRefreshing: Bool = false
    @State private var showCompletedTasks: Bool = true
    @State private var tabBarItems: [tabBarItem] = [
        tabBarItem(title: "all"),
        tabBarItem(title: "incomplete"),
        tabBarItem(title: "completed")
    ]
    @State private var tabBarViewIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.pathwayBold(20))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("your jungle")
                    .font(.pathwayBlack(24))

                Spacer()

                Button(action: {
                    // Add new task
                }) {
                    Image(systemName: "plus")
                        .font(.pathwayBold(20))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Custom tab bar for filtering
            TabBarView(
                tabBarItems: $tabBarItems,
                tabBarViewIndex: $tabBarViewIndex
            )

            if let currentUser = users.first {
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
                            ForEach(filteredTasks(currentUser.tasks)) { task in
                                taskCard(task: task)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            } else {
                Text("No user profile found")
                    .font(.pathway(18))
                    .padding()
            }

            Spacer()
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
        .navigationBarHidden(true)
        .onAppear {
            refreshTasks()
        }
    }

    private func filteredTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        switch tabBarViewIndex {
        case 0: // All tasks
            return tasks
        case 1: // Incomplete tasks
            return tasks.filter { !$0.completion.isCompleted }
        case 2: // Completed tasks
            return tasks.filter { $0.completion.isCompleted }
        default:
            return tasks
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
