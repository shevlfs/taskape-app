import SwiftData
import SwiftUI

struct UserJungleDetailedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var users: [taskapeUser]

    @State private var isRefreshing: Bool = false
    @State private var tabBarItems: [tabBarItem] = [
        tabBarItem(title: "all"),
        tabBarItem(title: "incomplete"),
        tabBarItem(title: "completed"),
        tabBarItem(title: "flagged"),
    ]
    @State private var tabBarViewIndex: Int = 0
    @State private var newTask: taskapeTask? = nil
    @State private var showNewTaskDetail: Bool = false
    @State private var draggingItem: taskapeTask?
    @State private var taskToRemove: taskapeTask? = nil
    @State private var completingAnimation: Bool = false
    @State private var showSortOptions: Bool = false

    // Enum for sorting options
    enum SortOption {
        case creationDate
        case deadline
        case priority
        case alphabetical
    }

    @State private var sortOption: SortOption = .creationDate
    @State private var sortAscending: Bool = false

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

                // Sort button
                Button(action: {
                    showSortOptions.toggle()
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.pathwayBold(18))
                        .foregroundColor(.primary)
                }
                .popover(isPresented: $showSortOptions) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sort by")
                            .font(.pathwayBold(16))
                            .padding(.top)

                        Divider()

                        Group {
                            sortOptionButton(option: .creationDate, label: "Creation Date")
                            sortOptionButton(option: .deadline, label: "Deadline")
                            sortOptionButton(option: .priority, label: "Priority")
                            sortOptionButton(option: .alphabetical, label: "Alphabetical")
                        }

                        Divider()

                        Toggle(isOn: $sortAscending) {
                            Text(sortAscending ? "Ascending" : "Descending")
                                .font(.pathway(15))
                        }
                        .padding(.horizontal)
                        .toggleStyle(SwitchToggleStyle(tint: .taskapeOrange))
                        .onChange(of: sortAscending) { _, _ in
                            refreshTasks()
                        }
                    }
                    .frame(width: 220)
                    .padding(.vertical)
                }

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
                    // Task list with completion animation handling
                    let tasks = sortedTasks(filteredTasks(currentUser.tasks))

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
                                if !(tabBarViewIndex == 1 && taskToRemove?.id == task.id && completingAnimation) {
                                    taskCard(task: task)
                                        .padding(.horizontal, 16)
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                        .animation(.easeInOut(duration: 0.3), value: completingAnimation)
                                        .onChange(of: task.completion.isCompleted) { oldValue, newValue in
                                            if tabBarViewIndex == 1 && oldValue == false && newValue == true {
                                                taskToRemove = task
                                                completingAnimation = true

                                                // Apply a delay before removing the task from view
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                    taskToRemove = nil
                                                    completingAnimation = false
                                                }
                                            }
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

    // Helper function for sort option buttons
    private func sortOptionButton(option: SortOption, label: String) -> some View {
        Button(action: {
            sortOption = option
            showSortOptions = false
            refreshTasks()
        }) {
            HStack {
                Text(label)
                    .font(.pathway(15))
                Spacer()
                if sortOption == option {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func filteredTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        switch tabBarViewIndex {
        case 0:  // All tasks
            return tasks
        case 1:  // Incomplete tasks
            return tasks.filter { !$0.completion.isCompleted }
        case 2:  // Completed tasks
            return tasks.filter { $0.completion.isCompleted }
        case 3:  // Flagged tasks
            return tasks.filter { $0.flagStatus }
        default:
            return tasks
        }
    }

    // Sort tasks based on the selected option
    private func sortedTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        var sortedTasks: [taskapeTask]

        switch sortOption {
        case .creationDate:
            sortedTasks = tasks.sorted {
                sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
            }
        case .deadline:
            sortedTasks = tasks.sorted { task1, task2 in
                // Handle nil deadlines
                guard let deadline1 = task1.deadline else {
                    return sortAscending ? false : true // nil deadlines go at the end or beginning
                }
                guard let deadline2 = task2.deadline else {
                    return sortAscending ? true : false
                }
                return sortAscending ? deadline1 < deadline2 : deadline1 > deadline2
            }
        case .priority:
            // Custom priority sorting logic (flagged tasks first, then by color priority)
            sortedTasks = tasks.sorted { task1, task2 in
                // First compare flag status
                if task1.flagStatus != task2.flagStatus {
                    return task1.flagStatus
                }

                // If both are flagged, compare colors
                if task1.flagStatus && task2.flagStatus {
                    // Define priority order for colors (can be customized)
                    let priorityOrder = ["#FF6B6B": 0, "#FFD166": 1, "#06D6A0": 2, "#118AB2": 3, "#073B4C": 4]

                    let priority1 = task1.flagColor.flatMap { priorityOrder[$0] } ?? 999
                    let priority2 = task2.flagColor.flatMap { priorityOrder[$0] } ?? 999

                    return sortAscending ? priority1 > priority2 : priority1 < priority2
                }

                // Fall back to creation date
                return sortAscending ? task1.createdAt < task2.createdAt : task1.createdAt > task2.createdAt
            }
        case .alphabetical:
            sortedTasks = tasks.sorted {
                sortAscending ? $0.name.lowercased() < $1.name.lowercased() : $0.name.lowercased() > $1.name.lowercased()
            }
        }

        // If we're not using custom ordering, respect the displayOrder field
        if sortOption == .creationDate && !sortAscending {
            // Use the custom order from the database (displayOrder field)
            return tasks.sorted { $0.displayOrder < $1.displayOrder }
        }

        return sortedTasks
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

        // Calculate the next display order value
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
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // The visual reordering is handled by SwiftUI based on the dragged item
        withAnimation(.default) {
            // This will be used to update in performDrop
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

#Preview {
    // Preview setup
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config)

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio: "I am a demo user",
            profileImage: "https://example.com/avatar.jpg",
            profileColor: "#2E86DE"
        )

        container.mainContext.insert(user)

        // Create some sample tasks
        let task1 = taskapeTask(
            id: UUID().uuidString,
            user_id: user.id,
            name: "Complete Project",
            taskDescription: "Finish all project tasks before deadline",
            author: "shevlfs",
            privacy: "private",
            displayOrder: 0
        )

        let task2 = taskapeTask(
            id: UUID().uuidString,
            user_id: user.id,
            name: "High Priority Task",
            taskDescription: "This needs immediate attention",
            author: "shevlfs",
            privacy: "private",
            flagStatus: true,
            flagColor: "#FF6B6B",
            displayOrder: 1
        )

        let task3 = taskapeTask(
            id: UUID().uuidString,
            user_id: user.id,
            name: "Completed Task",
            taskDescription: "This task is already done",
            author: "shevlfs",
            privacy: "public",
            displayOrder: 2
        )
        task3.completion.isCompleted = true

        container.mainContext.insert(task1)
        container.mainContext.insert(task2)
        container.mainContext.insert(task3)

        user.tasks = [task1, task2, task3]

        try container.mainContext.save()

        return UserJungleDetailedView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
