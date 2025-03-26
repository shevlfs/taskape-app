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
    @State private var currentUser: taskapeUser?
    @Namespace var mainNamespace

    @State var showFriendInvitationSheet: Bool = false

    @Binding var navigationPath: NavigationPath

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let user = currentUser {
                    Button(action: { navigationPath.append("self_jungle_view") }
                    ) {
                        UserJungleCard(user: user).matchedTransitionSource(
                            id: "jungleCard", in: mainNamespace
                        )
                    }.buttonStyle(PlainButtonStyle())
                    ScrollView {
                        HStack(spacing: 15) {
                            Button(action: {}) {
                                ZStack(alignment: .leading) {
                                    MenuItem(
                                        mainColor: Color(hex: "#FF7AAD"),
                                        widthProportion: 0.56,
                                        heightProportion: 0.16
                                    )

                                    HStack(alignment: .center, spacing: 10) {
                                        VStack {
                                            Text("🐒")
                                                .font(.system(size: 50))
                                        }.padding(.leading, 20)

                                        VStack(alignment: .leading, spacing: 2)
                                        {
                                            Text("ape-ify")
                                                .font(.pathwayBlack(21))
                                            Text("your friends'\nlives today!")
                                                .font(.pathwaySemiBold(19))

                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Right button - "new friend?"
                            Button(action: {
                                navigationPath.append("friendSearch")
                            }) {
                                ZStack {
                                    // Background using MenuItem component
                                    MenuItem(
                                        mainColor: Color(hex: "#E97451"),
                                        widthProportion: 0.32,
                                        heightProportion: 0.16
                                    )

                                    VStack(alignment: .center, spacing: 6) {

                                        Image(systemName: "plus.circle")
                                            .font(
                                                .system(
                                                    size: 45, weight: .medium)
                                            )
                                            .foregroundColor(.primary)

                                        Text("new\nfriend?")
                                            .font(.pathwaySemiBold(19))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }.matchedTransitionSource(
                                id: "friendSearch", in: mainNamespace
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ProgressView("Loading your jungle...")
                }
            }.navigationDestination(
                for: String.self,
                destination: {
                    route in
                    switch route {
                    case "self_jungle_view":
                        UserJungleDetailedView()
                            .modelContext(self.modelContext)
                            .navigationTransition(
                                .zoom(sourceID: "jungleCard", in: mainNamespace)
                            )
                    case "friendSearch":
                        FriendSearchView().toolbar(.hidden).modelContext(self.modelContext)
                            .navigationTransition(
                                .zoom(sourceID: "friendSearch", in: mainNamespace)
                            )
                    default:
                        EmptyView()
                    }
                }
            )
            .onAppear {
                currentUser = UserManager.shared.getCurrentUser(
                    context: modelContext)
            }
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

        return MainView(navigationPath: .constant(NavigationPath()))
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
