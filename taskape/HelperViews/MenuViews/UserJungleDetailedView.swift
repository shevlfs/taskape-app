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
        tabBarItem(title: "completed"),
    ]
    @State private var tabBarViewIndex: Int = 0

    @State private var newTask: taskapeTask? = nil
    @State private var showNewTaskDetail: Bool = false

    var body: some View {
        VStack(spacing: 0) {
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
                    createNewTask()
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
        // Sheet for new task detail view
        .sheet(isPresented: $showNewTaskDetail) {
            if let task = newTask {
                taskCardDetailView(
                    detailIsPresent: $showNewTaskDetail,
                    task: task
                ).onDisappear {
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error saving task locally: \(error)")
                    }

                    print("saving edited task")

                    Task {
                        await syncTaskChanges(
                            task: task)
                    }
                }
            }
        }
    }

    private func filteredTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        switch tabBarViewIndex {
        case 0:  // All tasks
            return tasks
        case 1:  // Incomplete tasks
            return tasks.filter { !$0.completion.isCompleted }
        case 2:  // Completed tasks
            return tasks.filter { $0.completion.isCompleted }
        default:
            return tasks
        }
    }

    private func refreshTasks() {
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""

        isRefreshing = true

        Task {
            guard let remoteTasks = await fetchTasks(userId: userId) else {
                print("Failed to fetch remote tasks")
                await MainActor.run {
                    isRefreshing = false
                }
                return
            }
            syncUserTasks(
                userId: userId, remoteTasks: remoteTasks,
                modelContext: modelContext)
            await MainActor.run {
                isRefreshing = false
            }
        }
    }

    private func createNewTask() {
        guard let currentUser = users.first else {
            print("No user found to associate task with")
            return
        }

        let userId =
            UserDefaults.standard.string(forKey: "user_id") ?? currentUser.id

        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: userId,
            name: "",
            taskDescription: "",
            author: currentUser.handle,
            privacy: "everyone"
        )

        modelContext.insert(task)
        currentUser.tasks.insert(task, at: 0)

        newTask = task
        saveNewTask()

        showNewTaskDetail = true
    }

    private func saveNewTask() {
        guard let task = newTask else { return }
        do {
            try modelContext.save()
            Task {
                let tasks = [task]
                _ = await submitTasksBatch(tasks: tasks)
            }
        } catch {
            print("Error saving new task: \(error)")
        }
    }
}
