import CachedAsyncImage
import SwiftData
import SwiftUI

struct MainNavigationView: View {
    @State private var selectedTabIndex: Int = 1
    @State var mainTabBarItems: [tabBarItem] = [
        tabBarItem(title: "settings"),
        tabBarItem(title: "main"),
    ]

    @State var eventsUpdated: Bool = false

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @State private var currentUser: taskapeUser?
    @Query var tasks: [taskapeTask]

    @State private var mainNavigationPath = NavigationPath()

    @State private var isLoading: Bool = true
    @State private var logoOpacity: Double = 1.0
    @State private var contentOpacity: Double = 0.0
    @State private var contentScale: CGFloat = 0.8

    @Namespace private var main

    @Binding var fullyLoaded: Bool

    @State var showGroupSheet: Bool = false

    @ObservedObject private var groupManager = GroupManager.shared

    var body: some View {
        NavigationStack(path: $mainNavigationPath) {
            VStack {
                UserGreetingCard(
                    user: $currentUser
                ).modelContext(modelContext).padding(.horizontal).padding(
                    .top, 10
                ).padding(.bottom, 10)

                MainMenuTabBarView(
                    tabBarItems: $mainTabBarItems,
                    tabBarViewIndex: $selectedTabIndex,
                    showGroupSheet: $showGroupSheet
                ).ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .toolbar(.hidden)

                if groupManager.selectedGroup != nil {
                    GroupContentView(
                        group: groupManager.selectedGroup!
                    )
                    .modelContext(modelContext)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: .infinity)
                    .toolbar(.hidden)
                    .gesture(createHorizontalSwipeGesture())
                } else {
                    switch selectedTabIndex {
                    case 0:
                        SettingsView()
                            .modelContext(modelContext)
                            .environmentObject(appState)
                            .gesture(createHorizontalSwipeGesture())
                    case 1:
                        MainView(
                            eventsUpdated: $eventsUpdated,
                            navigationPath: $mainNavigationPath
                        )
                        .modelContext(modelContext)
                        .ignoresSafeArea(.all)
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxHeight: .infinity)
                        .toolbar(.hidden)
                        .gesture(createHorizontalSwipeGesture())
                    default:
                        Text("Unknown view")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground))
                    }
                }

                Spacer()
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden)
            .sheet(isPresented: $showGroupSheet, content: {
                GroupCreationView().modelContext(modelContext)
            })
        }
        .onAppear {
            print($mainNavigationPath)
            currentUser = UserManager.shared.getCurrentUser(context: modelContext)

            groupManager.loadUserGroups(context: modelContext)
        }
    }

    private func createHorizontalSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) > abs(verticalAmount) {
                    handleHorizontalSwipe(horizontalAmount: horizontalAmount)
                }
            }
    }

    private func handleHorizontalSwipe(horizontalAmount: CGFloat) {
        withAnimation {
            if groupManager.selectedGroup != nil {
                if horizontalAmount > 0 {
                    selectedTabIndex = 1
                    groupManager.selectedGroup = nil
                }
            } else {
                if horizontalAmount < 0 {
                    selectedTabIndex = min(
                        selectedTabIndex + 1,
                        mainTabBarItems.count - 1
                    )
                } else {
                    selectedTabIndex = max(
                        0, selectedTabIndex - 1
                    )
                }
            }
        }
    }
}

struct GroupContentView: View {
    let group: taskapeGroup
    @Environment(\.modelContext) private var modelContext
    @State private var groupTasks: [taskapeTask] = []
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(group.name)
                .font(.pathwayBlack(24))
                .padding(.horizontal)

            if !group.group_description.isEmpty {
                Text(group.group_description)
                    .font(.pathway(16))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            if isLoading {
                ProgressView("Loading group tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if groupTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No tasks yet")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)

                    Button(action: {}) {
                        Text("Add a task")
                            .font(.pathway(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.taskapeOrange)
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(groupTasks) { task in
                            TaskListItem(task: task)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.top, 16)
        .onAppear {
            loadGroupTasks()
        }
    }

    private func loadGroupTasks() {
        isLoading = true

        Task {
            let tasks = await GroupManager.shared.loadGroupTasks(
                groupId: group.id,
                context: modelContext
            )

            await MainActor.run {
                groupTasks = tasks
                isLoading = false
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, taskapeGroup.self,
            configurations: config
        )

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio: "i am shevlfs",
            profileImage:
            "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
            profileColor: "blue"
        )

        container.mainContext.insert(user)

        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: user.id,
            name: "Sample Task",
            taskDescription: "This is a sample task description",
            author: "shevlfs",
            privacy: "private"
        )

        container.mainContext.insert(task)
        user.tasks.append(task)

        let group = taskapeGroup(
            id: UUID().uuidString,
            name: "Sample Group",
            group_description: "This is a sample group for testing",
            color: "#4CD97B",
            creatorId: user.id
        )

        container.mainContext.insert(group)

        try container.mainContext.save()

        return MainNavigationView(fullyLoaded: .constant(true))
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("failed to create preview: \(error.localizedDescription)")
    }
}
