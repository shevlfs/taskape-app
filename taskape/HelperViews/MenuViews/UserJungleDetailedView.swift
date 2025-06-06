import SwiftData
import SwiftUI

class FlagManager: ObservableObject {
    static let shared = FlagManager()

    @Published var flagChangeCounter: Int = 0

    func flagChanged() {
        DispatchQueue.main.async {
            self.flagChangeCounter += 1
        }
    }
}

class TaskFlag: Equatable, Hashable, Comparable {
    var flagName: String
    var flagColor: String

    init(flagname: String, flagcolor: String) {
        flagName = flagname
        flagColor = flagcolor
    }

    static func == (lhs: TaskFlag, rhs: TaskFlag) -> Bool {
        lhs.flagName == rhs.flagName
            && lhs.flagColor == rhs.flagColor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(flagName)
        hasher.combine(flagColor)
    }

    static func < (lhs: TaskFlag, rhs: TaskFlag) -> Bool {
        lhs.flagName < rhs.flagName
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

    @ObservedObject private var flagManager = FlagManager.shared

    @State private var isRefreshing: Bool = false
    @State private var tabBarItems: [tabBarItem] = []
    @State private var tabBarViewIndex: Int = 0
    @State private var newTask: taskapeTask? = nil
    @State private var showNewTaskDetail: Bool = false
    @State private var draggingItem: taskapeTask?

    @State private var completingTasks: [String: Bool] = [:]

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

            TabBarView(
                tabBarItems: $tabBarItems,
                tabBarViewIndex: $tabBarViewIndex
            ).padding(.bottom, 5)

            if let user = currentUser {
                if user.tasks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("no tasks here yet")
                            .font(.pathway(18))
                        Text("add a new task to start growing your jungle!")
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

                    if tasks.isEmpty {
                        Text("no tasks here yet")
                    } else {
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
                                value: tasks.count
                            )
                        }
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
            VStack {
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

        .onChange(of: flagManager.flagChangeCounter) { _, _ in
            if currentUser != nil {
                updateTabBarItems()
            }
        }
        .sheet(
            isPresented: $showNewTaskDetail,
            onDismiss: {
                if currentUser != nil {
                    updateTabBarItems()
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
        }.onAppear(perform: { uniqueFlags = getUserFlags(currentUser!) }).gesture(
            DragGesture(
                minimumDistance: 20,
                coordinateSpace: .global
            ).onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) > abs(verticalAmount) {
                    if horizontalAmount < 0 {
                        withAnimation {
                            tabBarViewIndex = min(
                                tabBarViewIndex + 1,
                                tabBarItems.count - 1
                            )
                        }
                    } else {
                        withAnimation {
                            tabBarViewIndex = max(
                                0, tabBarViewIndex - 1
                            )
                        }
                    }
                }
            })
    }

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

    private func filteredTasks(_ tasks: [taskapeTask]) -> [taskapeTask] {
        let tabType = getCurrentTabType()

        switch tabType {
        case .all:
            return tasks
        case .incomplete:

            return tasks.filter {
                !$0.completion.isCompleted || completingTasks[$0.id] == true
            }
        case .completed:
            return tasks.filter(\.completion.isCompleted)
        case .flagged:
            return tasks.filter(\.flagStatus)
        case let .flagType(flagName):
            return tasks.filter { $0.flagStatus && $0.flagName == flagName }
        }
    }

    private func handleTaskCompletion(task: taskapeTask) {
        if getCurrentTabType() == .incomplete, task.completion.isCompleted {
            withAnimation {
                completingTasks[task.id] = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    completingTasks[task.id] = nil
                }

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

        let maxOrder = user.tasks.map(\.displayOrder).max() ?? 0
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
                updateTabBarItems()

                let userId = UserManager.shared.currentUserId
                updateWidgetWithTasks(userId: userId, modelContext: modelContext)
            }

            Task {
                await syncTaskChanges(task: task)
            }
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

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
                GeometryReader { geo in
                    Color.clear.onAppear {
                        taskHeight = geo.size.height
                    }
                }
            )
            .onChange(of: task.completion.isCompleted) { oldValue, newValue in
                if oldValue == false, newValue == true {
                    onCompletion(task)
                }
            }

            .opacity(isDisappearing ? 0 : 1)
            .offset(x: isDisappearing ? 50 : 0)
            .frame(
                height: isDisappearing ? 0 : nil,
                alignment: .top
            )
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7),
                value: isDisappearing
            )
    }
}

struct TaskDropDelegate: DropDelegate {
    let item: taskapeTask
    let items: [taskapeTask]
    @Binding var draggedItem: taskapeTask?
    var modelContext: ModelContext

    func performDrop(info _: DropInfo) -> Bool {
        guard let draggedItem else {
            return false
        }

        if draggedItem.id == item.id {
            return false
        }

        let fromIndex = items.firstIndex { $0.id == draggedItem.id } ?? 0
        let toIndex = items.firstIndex { $0.id == item.id } ?? 0

        var updatedOrders: [(taskID: String, order: Int)] = []

        if fromIndex > toIndex {
            for i in toIndex ..< fromIndex {
                items[i].displayOrder += 1
                updatedOrders.append((items[i].id, items[i].displayOrder))
            }

            draggedItem.displayOrder = items[toIndex].displayOrder - 1
            updatedOrders.append((draggedItem.id, draggedItem.displayOrder))
        }

        else if fromIndex < toIndex {
            for i in (fromIndex + 1) ... toIndex {
                items[i].displayOrder -= 1
                updatedOrders.append((items[i].id, items[i].displayOrder))
            }

            draggedItem.displayOrder = items[toIndex].displayOrder + 1
            updatedOrders.append((draggedItem.id, draggedItem.displayOrder))
        }

        do {
            try modelContext.save()

            Task {
                if let userId = items.first?.user_id, !userId.isEmpty {
                    let success = await updateTaskOrder(
                        userID: userId, taskOrders: updatedOrders
                    )
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

    func dropEntered(info _: DropInfo) {
        guard let draggedItem,
              draggedItem.id != item.id
        else {
            return
        }

        withAnimation(.default) {}
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
