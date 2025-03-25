//
//  ContentView.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct userGreetingCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var user: taskapeUser?

    var body: some View {
        HStack {
            if let user = user {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 60, height: 60)
                    .background(
                        CachedAsyncImage(url: URL(string: user.profileImageURL))
                        {
                            phase in
                            switch phase {
                            case .failure:
                                Image(systemName: "photo")
                            case .success(let image):
                                image.resizable()
                            default:
                                ProgressView()
                            }
                        }
                    )
                    .cornerRadius(106.50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 106.50)
                            .inset(by: 0.50)
                            .stroke(
                                Color(red: 0.46, green: 0.46, blue: 0.50)
                                    .opacity(
                                        0.12), lineWidth: 0.50
                            )
                    ).padding(.leading)

                HStack {
                    Text("ooga-booga,").font(.pathway(16))
                    Text("\(user.handle)").font(.pathwayBlack(16))
                }
            } else {
                EmptyView()
            }
            Spacer()
        }
        .onAppear {
            user = UserManager.shared.getCurrentUser(context: modelContext)
        }
    }
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

    var body: some View {
        NavigationStack(path: $mainNavigationPath) {
            VStack {
                userGreetingCard()
                TabBarView(
                    tabBarItems: $mainTabBarItems,
                    tabBarViewIndex: $selectedTabIndex
                )

                switch selectedTabIndex {
                case 0:
                    SettingsView().modelContext(modelContext).environmentObject(appState)
                case 1:
                    MainView(navigationPath: $mainNavigationPath)
                        .modelContext(modelContext)
                default:
                    Text("Unknown")
                }
                Spacer()
            }
        }
        .onAppear {
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

        return MainNavigationView()
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
