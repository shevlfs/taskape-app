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

    var body: some View {
        NavigationStack(path: $mainNavigationPath) {
            VStack {
                UserGreetingCard(
                    user: $currentUser
                ).modelContext(modelContext).padding(.horizontal).padding(
                    .top, 10
                ).padding(.bottom, 10)
                TabBarView(
                    tabBarItems: $mainTabBarItems,
                    tabBarViewIndex: $selectedTabIndex
                ).ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .toolbar(.hidden)

                switch selectedTabIndex {
                case 0:
                    SettingsView().modelContext(modelContext).environmentObject(
                        appState
                    ).gesture(
                        DragGesture(
                            minimumDistance: 20,
                            coordinateSpace: .global
                        ).onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            if abs(horizontalAmount) > abs(verticalAmount) {
                                if horizontalAmount < 0 {
                                    withAnimation {
                                        selectedTabIndex = min(
                                            selectedTabIndex + 1,
                                            mainTabBarItems.count - 1
                                        )
                                    }
                                } else {
                                    withAnimation {
                                        selectedTabIndex = max(
                                            0, selectedTabIndex - 1
                                        )
                                    }
                                }
                            }
                        })
                case 1:
                    MainView(
                        eventsUpdated: $eventsUpdated,
                        navigationPath: $mainNavigationPath
                    )
                    .modelContext(modelContext)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: .infinity).toolbar(.hidden).gesture(
                        DragGesture(
                            minimumDistance: 20,
                            coordinateSpace: .global
                        ).onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            if abs(horizontalAmount) > abs(verticalAmount) {
                                if horizontalAmount < 0 {
                                    withAnimation {
                                        selectedTabIndex = min(
                                            selectedTabIndex + 1,
                                            mainTabBarItems.count - 1
                                        )
                                    }
                                } else {
                                    withAnimation {
                                        selectedTabIndex = max(
                                            0, selectedTabIndex - 1
                                        )
                                    }
                                }
                            }
                        })
                default:
                    Text("unknown")
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden)
        }
        .onAppear {
            print($mainNavigationPath)
            currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config
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

        try container.mainContext.save()

        return MainNavigationView(fullyLoaded: .constant(true))
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("failed to create preview: \(error.localizedDescription)")
    }
}
