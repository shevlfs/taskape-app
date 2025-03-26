import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentUser: taskapeUser?
    @Namespace var mainNamespace

    @State var showFriendInvitationSheet: Bool = false

    // Add ObservedObject for friend manager to get request counts
    @ObservedObject private var friendManager = FriendManager.shared

    // State to track if we're currently fetching friend data
    @State private var isLoadingFriendData: Bool = false

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

                            // Right button - "new friend?" with notification badge
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
                                        // Add notification badge to image if we have friend requests
                                        ZStack {
                                            Image(systemName: "plus.circle")
                                                .font(
                                                    .system(
                                                        size: 45,
                                                        weight: .medium)
                                                )
                                                .foregroundColor(.primary)

                                            // Show notification badge if we have friend requests
                                        }

                                        Text("new\nfriend?")
                                            .font(.pathwaySemiBold(19))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }

                                    if friendManager.incomingRequests
                                        .count > 0
                                    {
                                        Text(
                                            "\(friendManager.incomingRequests.count)"
                                        )
                                        .font(.pathwayBoldCondensed(12))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 30, y: -50)
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
                    VStack(alignment: .center) {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView("loading...").font(.pathwayBold(20))
                            Spacer()
                        }
                        Spacer()
                    }
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
                        FriendSearchView().toolbar(.hidden).modelContext(
                            self.modelContext
                        )
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

                // Fetch friend data when view appears
                if !isLoadingFriendData {
                    isLoadingFriendData = true
                    Task {
                        await friendManager.refreshFriendData()
                        await MainActor.run {
                            isLoadingFriendData = false
                        }
                    }
                }
                setupWidgetSync()
            }
        }
    }
    func setupWidgetSync() {
        if let user = currentUser {
            UserManager.shared.syncTasksWithWidget(context: modelContext)
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
