import SwiftData
import SwiftUI

class FlagManager: ObservableObject {
    static let shared = FlagManager()

    @Published var flagChangeCounter: Int = 0

    func flagChanged() {
        // Increment counter to trigger any views observing this publisher
        DispatchQueue.main.async {
            self.flagChangeCounter += 1
        }
    }
}

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var users: [taskapeUser]

    // Observe the flag manager to detect changes
    @ObservedObject private var flagManager = FlagManager.shared

    @State private var isRefreshing: Bool = false
    @State private var tabBarItems: [tabBarItem] = []
    @State private var tabBarViewIndex: Int = 0
    @State private var newTask: taskapeTask? = nil
    @State private var showNewTaskDetail: Bool = false
    @State private var draggingItem: taskapeTask?
    @State private var taskToRemove: taskapeTask? = nil
    @State private var completingAnimation: Bool = false

    // Tab types - first the fixed tabs, then dynamic flag tabs
    private enum TabType: Equatable {
        case all
        case incomplete
        case completed
        case flagged
        case flagType(String)
    }

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

            // Tab bar with standard tabs and flag-based tabs
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
                    // Task list filtered by the selected tab
                    let tasks = filteredTasks(currentUser.tasks)
                        .sorted { $0.displayOrder < $1.displayOrder }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
                                if !(getCurrentTabType() == .incomplete &&
                                     taskToRemove?.id == task.id &&
                                     completingAnimation) {
                                    taskCard(task: task)
                                        .padding(.horizontal, 16)
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                        .animation(.easeInOut(duration: 0.3), value: completingAnimation)
                                        .onChange(of: task.completion.isCompleted) { oldValue, newValue in
                                            handleTaskCompletion(task: task, oldValue: oldValue, newValue: newValue)
                                        }
                                        .onDrag {
                                            self.draggingItem = task
                                            return NSItemProvider(object: task.id as NSString)
                                        }
                                        .onDrop(of: [.text], delegate: TaskDropDelegate(
                                            item: task,
                                            items: tasks,
                                            draggedItem: $draggingItem,
                                            modelContext: modelContext
                                        ))
                                }
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
            updateTabBarItems()
        }
        .onChange(of: users.first?.tasks.count) { _, _ in
            updateTabBarItems()
        }
        // Observe the flag manager for changes
        .onChange(of: flagManager.flagChangeCounter) { _, _ in
            print("updating tab bar items")
            updateTabBarItems()
        }
        .sheet(isPresented: $showNewTaskDetail, onDismiss: {
            updateTabBarItems() // Update tabs when sheet is dismissed
        }) {
            if let task = newTask {
                taskCardDetailView(
                    detailIsPresent: $showNewTaskDetail,
                    task: task
                ).onDisappear {
                    saveTaskChanges(task: task)
                }
            }
        }
    }

    // Get all unique flag names from user's tasks
    private func getUserFlagNames() -> [String] {
        guard let user = users.first else { return [] }

        var flagNames: Set<String> = []
        for task in user.tasks {
            if let flagName = task.flagName, task.flagStatus {
                flagNames.insert(flagName)
            }
        }
        return Array(flagNames).sorted()
    }

    // Update the tab bar items with standard tabs and flag tabs
    private func updateTabBarItems() {
        var items = [
            tabBarItem(title: "to-do"),
            tabBarItem(title: "done"),
        ]

        // Add flag-specific tabs
        let flagNames = getUserFlagNames()
        for flagName in flagNames {
            items.append(tabBarItem(title: flagName))
        }

        tabBarItems = items
    }

    // Get the tab type for the current selected index
    private func getCurrentTabType() -> TabType {
        guard tabBarViewIndex < tabBarItems.count else { return .all }

        switch tabBarViewIndex {
        case 0: return .incomplete
        case 1: return .completed
        default:
            let flagName = tabBarItems[tabBarViewIndex].title
            return .flagType(flagName)
        }
    }

    // Filter tasks based on the selected tab
    private func filteredTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        let tabType = getCurrentTabType()

        switch tabType {
        case .all:
            return tasks
        case .incomplete:
            return tasks.filter { !$0.completion.isCompleted }
        case .completed:
            return tasks.filter { $0.completion.isCompleted }
        case .flagged:
            return tasks.filter { $0.flagStatus }
        case .flagType(let flagName):
            return tasks.filter { $0.flagStatus && $0.flagName == flagName }
        }
    }

    // Handle task completion animation
    private func handleTaskCompletion(task: taskapeTask, oldValue: Bool, newValue: Bool) {
        if getCurrentTabType() == .incomplete && oldValue == false && newValue == true {
            taskToRemove = task
            completingAnimation = true

            // Apply a delay before removing the task from view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                taskToRemove = nil
                completingAnimation = false
            }
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
                updateTabBarItems()
            }
        }
    }

    private func createNewTask() {
        guard let currentUser = users.first else {
            print("No user found to associate task with")
            return
        }

        let userId = UserDefaults.standard.string(forKey: "user_id") ?? currentUser.id

        // Calculate the next display order value - place new task at the top
        let maxOrder = currentUser.tasks.map { $0.displayOrder }.max() ?? 0
        let nextOrder = maxOrder + 1

        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: userId,
            name: "",
            taskDescription: "",
            author: currentUser.handle,
            privacy: PrivacySettings(level: .everyone),
            displayOrder: nextOrder
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

    private func saveTaskChanges(task: taskapeTask) {
        do {
            try modelContext.save()
            updateTabBarItems() // Update tabs in case flag changed

            Task {
                await syncTaskChanges(task: task)
            }
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

// Task drop delegate for drag-and-drop reordering
struct TaskDropDelegate: DropDelegate {
    let item: taskapeTask
    let items: [taskapeTask]
    @Binding var draggedItem: taskapeTask?
    var modelContext: ModelContext

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else {
            return false
        }

        // Exit if it's the same item
        if draggedItem.id == item.id {
            return false
        }

        // Get the source and destination indices
        let fromIndex = items.firstIndex { $0.id == draggedItem.id } ?? 0
        let toIndex = items.firstIndex { $0.id == item.id } ?? 0

        // Calculate new display orders for all affected tasks
        var updatedOrders: [(taskID: String, order: Int)] = []

        // If moving up in the list
        if fromIndex > toIndex {
            // Increment display orders for items between the destination and source
            for i in toIndex..<fromIndex {
                items[i].displayOrder += 1
                updatedOrders.append((items[i].id, items[i].displayOrder))
            }

            // Set the dragged item's display order
            draggedItem.displayOrder = items[toIndex].displayOrder - 1
            updatedOrders.append((draggedItem.id, draggedItem.displayOrder))
        }
        // If moving down in the list
        else if fromIndex < toIndex {
            // Decrement display orders for items between source and destination
            for i in (fromIndex + 1)...toIndex {
                items[i].displayOrder -= 1
                updatedOrders.append((items[i].id, items[i].displayOrder))
            }

            // Set the dragged item's display order
            draggedItem.displayOrder = items[toIndex].displayOrder + 1
            updatedOrders.append((draggedItem.id, draggedItem.displayOrder))
        }

        // Save changes locally
        do {
            try modelContext.save()

            // Update the server with the new task orders
            Task {
                if let userId = items.first?.user_id, !userId.isEmpty {
                    let success = await updateTaskOrder(userID: userId, taskOrders: updatedOrders)
                    if success {
                        print("Task orders successfully updated on server")
                    } else {
                        print("Failed to update task orders on server")
                    }
                }
            }

            return true
        } catch {
            print("Error saving reordered tasks: \(error)")
            return false
        }
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem,
              draggedItem.id != item.id else {
            return
        }

        // Visual feedback handled by SwiftUI
        withAnimation(.default) { }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
