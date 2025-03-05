//
//  SwiftUIView.swift
//  taskape
//
//  Created by shevlfs on 3/5/25.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var users: [taskapeUser]
    @Query var tasks: [taskapeTask]
    @Namespace private var mainNamespace

    @Binding var navigationPath: NavigationPath
    var body: some View {
        VStack {
            UserJungleCard(user: users.first!).onTapGesture {
                navigationPath.append("self_jungle_view")
            }
            ScrollView {

            }
        }.navigationDestination(
            for: String.self,
            destination: {
                route in
                switch route {
                case "self_jungle_view":
                    UserJungleDetailedView()
                        .modelContext(self.modelContext)
                        .navigationTransition(.zoom(sourceID: "" , in: mainNamespace))
                default:
                    EmptyView()
                }
            })
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

        return MainView(navigationPath: .constant(NavigationPath()))
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
