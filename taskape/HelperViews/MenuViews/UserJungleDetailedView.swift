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

class TaskFlag: Equatable, Hashable, Comparable {
    var flagName: String
    var flagColor: String

    init(flagname: String, flagcolor: String) {
        self.flagName = flagname
        self.flagColor = flagcolor
    }

    static func == (lhs: TaskFlag, rhs: TaskFlag) -> Bool {
        return lhs.flagName == rhs.flagName
            && lhs.flagColor == rhs.flagColor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(flagName)
        hasher.combine(flagColor)
    }

    static func < (lhs: TaskFlag, rhs: TaskFlag) -> Bool {
        return lhs.flagName < rhs.flagName
    }
}

func getUserFlags(_ user: taskapeUser) -> [TaskFlag] {
    var flagNames: Set<TaskFlag> = []
    for task in user.tasks {
        if let flagName = task.flagName, task.flagStatus,
            let flagColor = task.flagColor
        {
            flagNames.insert(
                TaskFlag(flagname: flagName, flagcolor: flagColor))
        }
    }
    return Array(flagNames).sorted()
}

var uniqueFlags: [TaskFlag] = []

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentUser: taskapeUser?

    // Observe the flag manager to detect changes
    @ObservedObject private var flagManager = FlagManager.shared

    @State private var isRefreshing: Bool = false
    @State private var tabBarItems: [tabBarItem] = []
    @State private var tabBarViewIndex: Int = 0
    @State private var newTask: taskapeTask? = nil
    @State private var showNewTaskDetail: Bool = false
    @State private var draggingItem: taskapeTask?

    // Animation states for task completion
    @State private var completingTasks: [String: Bool] = [:]

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

            if let user = currentUser {
                if user.tasks.isEmpty {
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
                    let tasks = filteredTasks(user.tasks)
                        .sorted { $0.displayOrder < $1.displayOrder }
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
                                AnimatedTaskCard(
                                    task: task,
                                    isDisappearing: completingTasks[task.id]
                                        ?? false,
                                    onCompletion: { completedTask in
                                        handleTaskCompletion(
                                            task: completedTask)
                                    }, labels: getUserFlags(currentUser!)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7),
                            value: tasks.count)
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
            currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)
            if currentUser != nil {
                updateTabBarItems()
            }
        }
        .onChange(of: currentUser?.tasks.count) { _, _ in
            if currentUser != nil {
                updateTabBarItems()
            }
        }
        // Observe the flag manager for changes
        .onChange(of: flagManager.flagChangeCounter) { _, _ in
            if currentUser != nil {
                updateTabBarItems()
            }
        }
        .sheet(
            isPresented: $showNewTaskDetail,
            onDismiss: {
                if currentUser != nil {
                    updateTabBarItems()  // Update tabs when sheet is dismissed
                }
            }
        ) {
            if let task = newTask {
                taskCardDetailView(
                    detailIsPresent: $showNewTaskDetail,
                    task: task,
                    labels: getUserFlags(
                        currentUser!
                    )
                ).onDisappear {
                    saveTaskChanges(task: task)
                }
            }
        }.onAppear(perform: { uniqueFlags = getUserFlags(currentUser!) })
    }

    // Update the tab bar items with standard tabs and flag tabs
    private func updateTabBarItems() {
        var items = [
            tabBarItem(title: "to-do"),
            tabBarItem(title: "done"),
        ]

        if let user = currentUser {
            let flags = getUserFlags(user)
            uniqueFlags = getUserFlags(user)
            for flag in flags {
                items.append(
                    tabBarItem(title: flag.flagName, color: flag.flagColor))
            }
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
            // Include incomplete tasks and tasks that are currently being animated out
            return tasks.filter {
                !$0.completion.isCompleted || completingTasks[$0.id] == true
            }
        case .completed:
            return tasks.filter { $0.completion.isCompleted }
        case .flagged:
            return tasks.filter { $0.flagStatus }
        case .flagType(let flagName):
            return tasks.filter { $0.flagStatus && $0.flagName == flagName }
        }
    }

    // Handle task completion with animation
    private func handleTaskCompletion(task: taskapeTask) {
        if getCurrentTabType() == .incomplete && task.completion.isCompleted {
            // Mark the task as being animated out
            withAnimation {
                completingTasks[task.id] = true
            }

            // After animation completes, remove task from the animating set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    completingTasks[task.id] = nil
                }
                // Save the task changes to the server
                Task {
                    await syncTaskChanges(task: task)
                }
            }
        }
    }

    private func refreshTasks() {
        let userId = UserManager.shared.currentUserId
        guard !userId.isEmpty else { return }

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
                userId: userId,
                remoteTasks: remoteTasks,
                modelContext: modelContext
            )

            await MainActor.run {
                isRefreshing = false
                currentUser = UserManager.shared.getCurrentUser(
                    context: modelContext)
                if currentUser != nil {
                    updateTabBarItems()
                }
            }
        }
    }

    private func createNewTask() {
        guard let user = currentUser else { return }

        let userId = UserManager.shared.currentUserId

        // Calculate the next display order value - place new task at the top
        let maxOrder = user.tasks.map { $0.displayOrder }.max() ?? 0
        let nextOrder = maxOrder + 1

        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: userId,
            name: "",
            taskDescription: "",
            author: user.handle,
            privacy: PrivacySettings(level: .everyone),
            displayOrder: nextOrder
        )

        modelContext.insert(task)
        user.tasks.insert(task, at: 0)

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
            if currentUser != nil {
                updateTabBarItems()  // Update tabs in case flag changed
            }

            Task {
                await syncTaskChanges(task: task)
            }
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

// Animated task card component
struct AnimatedTaskCard: View {
    @Bindable var task: taskapeTask
    var isDisappearing: Bool
    var onCompletion: (taskapeTask) -> Void

    @State private var taskHeight: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0

    @State var labels: [TaskFlag] = []

    var body: some View {
        TaskCardWithCheckbox(task: task, labels: $labels)
            .background(
                // Measure the height of the task card
                GeometryReader { geo in
                    Color.clear.onAppear {
                        taskHeight = geo.size.height
                    }
                }
            )
            .onChange(of: task.completion.isCompleted) { oldValue, newValue in
                if oldValue == false && newValue == true {
                    onCompletion(task)
                }
            }
            // Apply animations when task is being removed
            .opacity(isDisappearing ? 0 : 1)
            .offset(x: isDisappearing ? 50 : 0)
            .frame(
                height: isDisappearing ? 0 : nil,
                alignment: .top
            )
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7),
                value: isDisappearing)
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
                    let success = await updateTaskOrder(
                        userID: userId, taskOrders: updatedOrders)
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
            draggedItem.id != item.id
        else {
            return
        }

        // Visual feedback handled by SwiftUI
        withAnimation(.default) {}
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
