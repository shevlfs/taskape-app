import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentUser: taskapeUser?
    @Namespace var mainNamespace

    @Binding var eventsUpdated: Bool

    // Event-related state
    @State private var events: [taskapeEvent] = []
    @State private var isLoadingEvents: Bool = false

    @State var showFriendInvitationSheet: Bool = false

    // Add ObservedObject for friend manager to get request countsr
    @ObservedObject private var friendManager = FriendManager.shared

    // State to track if we're currently fetching friend data
    @State private var isLoadingFriendData: Bool = false

    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            if let user = currentUser {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .center, spacing: 10) {
                        Button(action: {
                            navigationPath.append("self_jungle_view")
                        }
                        ) {
                            UserJungleCard(user: user).matchedTransitionSource(
                                id: "jungleCard", in: mainNamespace
                            )
                        }.buttonStyle(PlainButtonStyle()).padding(.top, 10)
                        if isLoadingEvents {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 16)
                            }
                        }

                        if !events.isEmpty && !isLoadingEvents {
                            // Group events into pairs or individual cards based on size
                            let chunkedEvents = createLayoutGroups(
                                from: events)

                            ForEach(
                                0..<chunkedEvents.count, id: \.self
                            ) { index in
                                let group = chunkedEvents[index]

                                // For paired events (horizontal layout)
                                if group.count == 2 {
                                    HStack(spacing: 20) {
                                        ForEach(group) { event in
                                            Button(action: {
                                                navigationPath
                                                    .append(event.id)
                                            }) {
                                                EventCard(
                                                    event: event,
                                                    eventSize: event
                                                        .eventSize
                                                )
                                                .matchedTransitionSource(
                                                    id: event.id,
                                                    in: mainNamespace
                                                )
                                            }.buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                // For single event (could be small, medium, or large)
                                else if let singleEvent = group
                                    .first
                                {
                                    if singleEvent.eventSize == .large {
                                        // Large events get full width
                                        Button(action: {
                                            navigationPath
                                                .append(singleEvent.id)
                                        }) {
                                            EventCard(
                                                event: singleEvent,
                                                eventSize: singleEvent
                                                    .eventSize
                                            )
                                            .matchedTransitionSource(
                                                id: singleEvent.id,
                                                in: mainNamespace
                                            )
                                        }.buttonStyle(PlainButtonStyle())
                                    } else {
                                        // For small or medium events, create a layout with appropriate spacing
                                        HStack(spacing: 20) {
                                            if group.first?.position == .right {
                                                // Empty space (nothing) on the left
                                                Spacer()
                                                    .frame(maxWidth: .infinity)

                                                // Event on the right
                                                Button(action: {
                                                    navigationPath
                                                        .append(singleEvent.id)
                                                }) {
                                                    EventCard(
                                                        event: singleEvent,
                                                        eventSize: singleEvent
                                                            .eventSize
                                                    ).padding(.trailing, 15)
                                                        .matchedTransitionSource(
                                                            id: singleEvent.id,
                                                            in: mainNamespace
                                                        )
                                                }.buttonStyle(
                                                    PlainButtonStyle())
                                            } else {
                                                // Event on the left
                                                Button(action: {
                                                    navigationPath
                                                        .append(singleEvent.id)
                                                }) {
                                                    EventCard(
                                                        event: singleEvent,
                                                        eventSize: singleEvent
                                                            .eventSize
                                                    ).padding(.leading, 15)
                                                        .matchedTransitionSource(
                                                            id: singleEvent.id,
                                                            in: mainNamespace
                                                        )
                                                }.buttonStyle(
                                                    PlainButtonStyle())

                                                // Empty space (nothing) on the right
                                                Spacer()
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                        } else if events.isEmpty && !isLoadingEvents {
                            // Keep your existing empty state code here
                            if friendManager.friends.isEmpty {
                                VStack(spacing: 8) {
                                    Text("no friends yet")
                                        .font(.pathway(16))
                                        .foregroundColor(.secondary)

                                    Text(
                                        "add some friends to see their activity"
                                    )
                                    .font(.pathwayItalic(14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .center
                                )
                                .padding(.vertical, 20)
                            } else {
                                Text("no events yet")
                                    .font(.pathway(16))
                                    .foregroundColor(.secondary)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .center
                                    )
                                    .padding(.vertical, 20)
                            }
                        }
                        HStack(spacing: 20) {
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

                                        VStack(
                                            alignment: .leading, spacing: 2
                                        ) {
                                            Text("ape-ify")
                                                .font(.pathwayBlack(21))
                                            Text(
                                                "your friends'\nlives today!"
                                            )
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
                                        }

                                        Text("new\nfriend?")
                                            .font(.pathwaySemiBold(19))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }

                                    if friendManager.incomingRequests.count > 0
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
                    }
                }.fadeOutTop(fadeLength: 10)
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
        }
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(
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
                    ZStack {
                        FriendSearchView()
                            .modelContext(self.modelContext)
                    }.toolbar(.hidden)
                        .navigationTransition(
                            .zoom(sourceID: "friendSearch", in: mainNamespace)
                        )
                default:
                    if let event = events.first(where: { $0.id == route }) {
                        EventCardDetailedView(event: event)
                            .navigationTransition(
                                .zoom(sourceID: event.id, in: mainNamespace)
                            )
                            .modelContext(self.modelContext)
                            .navigationBarBackButtonHidden().toolbar(.hidden)
                    } else {

                        Text("error in the mainview navigation!")
                    }
                }
            }
        )
        .onAppear {
            currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)

            isLoadingFriendData = true
            Task {
                await friendManager.refreshFriendData()
                await MainActor.run {
                    isLoadingFriendData = false

                    // Fetch events after we have friend data
                    fetchEvents()
                }
            }
        }
    }

    // Function to fetch events from the server
    private func fetchEvents() {
        guard let user = currentUser else { return }

        // Don't continue if there are no friends
        if friendManager.friends.isEmpty && !isLoadingFriendData {
            return
        }

        isLoadingEvents = true
        events = []  // Clear any existing events

        Task {
            // First, preload all tasks for all friends
            await friendManager.preloadAllFriendTasks()
            var allEvents: [taskapeEvent] = []

            if let userEvents = await taskape.fetchEvents(userId: user.id) {
                // Filter to only include events from friends
                let friendIds = friendManager.friends.map { $0.id }

                // Group events by friend ID
                var latestEventByFriend: [String: taskapeEvent] = [:]

                // For each event, check if it's from a friend and if it's the latest one
                for event in userEvents {
                    // Only process events from friends
                    if friendIds.contains(event.userId) {
                        // If we don't have an event for this friend yet, or this event is newer
                        if let existingEvent = latestEventByFriend[event.userId]
                        {
                            if event.createdAt > existingEvent.createdAt {
                                latestEventByFriend[event.userId] = event
                            }
                        } else {
                            latestEventByFriend[event.userId] = event
                        }
                    }
                }

                // Convert dictionary values to array
                let filteredEvents = Array(latestEventByFriend.values)

                // For each event, associate the relevant tasks from the pre-loaded tasks

                for event in filteredEvents {
                    if !event.taskIds.isEmpty {
                        // Get the tasks for this friend that match the task IDs in the event
                        let relevantTasks = await friendManager.getTasksByIds(
                            friendId: event.userId,
                            taskIds: event.taskIds
                        )

                        await MainActor.run {
                            // Add these tasks to the event
                            for task in relevantTasks {
                                if !event.relatedTasks.contains(where: {
                                    $0.id == task.id
                                }) {
                                    event.relatedTasks.append(task)

                                    // Ensure the task is in the model context
                                    modelContext.insert(task)
                                }
                            }
                        }
                    }

                    allEvents.append(event)
                }
            }

            await MainActor.run {
                events = allEvents
                isLoadingEvents = false

                // Save context after adding tasks
                do {
                    try modelContext.save()
                } catch {
                    print("error saving context after loading tasks: \(error)")
                }
            }
            eventsUpdated = true
        }
    }

    // Add this helper function inside the MainView struct
    private func createLayoutGroups(from events: [taskapeEvent])
        -> [[taskapeEvent]]
    {
        var result: [[taskapeEvent]] = []
        var currentIndex = 0

        while currentIndex < events.count {
            let event = events[currentIndex]

            switch event.eventSize {
            case .large:
                // Large events always get their own row
                result.append([event])
                currentIndex += 1

            case .medium:
                // Check if we can pair with a small event
                if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .small
                {
                    // Medium + Small
                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else {
                    // Medium only - leave the second position empty
                    result.append([event])
                    currentIndex += 1
                }

            case .small:
                // Check if we can pair with a medium event
                if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .medium
                {
                    // Small + Medium
                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .small
                {
                    // Small + Small
                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else {
                    // Small only - leave the second position empty
                    result.append([event])
                    currentIndex += 1
                }

            default:
                // For any other sizes, add individually
                result.append([event])
                currentIndex += 1
            }
        }

        return result
    }

    func setupWidgetSync() {
        if let user = currentUser {
            UserManager.shared.syncTasksWithWidget(context: modelContext)
        }
    }
}

extension taskapeEvent {
    var position: EventPosition {
        // Use the UUID as a deterministic way to decide position
        // This ensures consistency across app launches
        let uuidString = self.id
        let firstChar = uuidString.first ?? "0"
        return firstChar.asciiValue?.isMultiple(of: 2) == true
            ? .left : .right
    }
}

enum EventPosition {
    case left
    case right
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

        return MainView(
            eventsUpdated: .constant(false),
            navigationPath: .constant(NavigationPath())
        )
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

extension View {
    func fadeOutTop(fadeLength: CGFloat = 50) -> some View {
        return mask(
            VStack(spacing: 0) {

                // Top gradient
                LinearGradient(
                    gradient:
                        Gradient(
                            colors: [Color.black.opacity(0), Color.black]),
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: fadeLength)

                Rectangle().fill(Color.black)
            }
        )
    }
}
