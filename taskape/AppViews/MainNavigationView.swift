//
//  ContentView.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct navigationItem {
    
}

struct MainNavigationView: View {
    @State private var selectedTabIndex: Int = 1
    @State var mainTabBarItems: [tabBarItem] = [
        tabBarItem(title: "settings"),
        tabBarItem(title: "main"),
    ]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @State private var currentUser: taskapeUser?
    @Query var tasks: [taskapeTask]

    @State private var mainNavigationPath = NavigationPath()

    // Loading and animation states
    @State private var isLoading: Bool = true
    @State private var logoOpacity: Double = 1.0
    @State private var contentOpacity: Double = 0.0
    @State private var contentScale: CGFloat = 0.8

    @Binding var fullyLoaded: Bool

    var body: some View {
            // Main Navigation content
            NavigationStack(path: $mainNavigationPath) {
                VStack {
                    userGreetingCard()
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
                                            self.selectedTabIndex = min(
                                                self.selectedTabIndex + 1,
                                                self.mainTabBarItems.count - 1)
                                        }
                                    } else {
                                        withAnimation {
                                            self.selectedTabIndex = max(
                                                0, self.selectedTabIndex - 1)
                                        }
                                    }
                                }
                            })
                    case 1:
                        MainView(navigationPath: $mainNavigationPath)
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
                                                self.selectedTabIndex = min(
                                                    self.selectedTabIndex + 1,
                                                    self.mainTabBarItems.count - 1)
                                            }
                                        } else {
                                            withAnimation {
                                                self.selectedTabIndex = max(
                                                    0, self.selectedTabIndex - 1)
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
            .navigationDestination(
                for: String.self,
                destination: {
                    route in
                    switch route {
                    case "self_jungle_view":
                        UserJungleDetailedView()
                            .modelContext(self.modelContext)
                    case "friendSearch":
                        FriendSearchView().toolbar(.hidden).modelContext(
                            self.modelContext)
                    default:
                        EmptyView()
                    }
                }
            )
        .onAppear{
            currentUser = UserManager.shared.getCurrentUser(context: modelContext)
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
