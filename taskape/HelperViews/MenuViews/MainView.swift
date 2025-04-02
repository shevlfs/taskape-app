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
    @State private var lastRefreshTime: Date = Date().addingTimeInterval(-60)
    @State private var newEventIds: Set<String> = [] // Track new events for animation
    @State private var seenEventIds: Set<String> = [] // Track events user has already seen

    // Animation properties
    @State private var animateNewEvents: Bool = false

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

                        if isLoadingEvents && events.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 16)
                            }
                        }

                        if !events.isEmpty {
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
                                            NavigationLink(
                                                destination: {EventCardDetailedView(event: event).modelContext(modelContext).navigationTransition(.zoom(sourceID: event.id, in: mainNamespace))}) {
                                                    EventCard(
                                                        event: event,
                                                        eventSize: event
                                                            .eventSize
                                                    )
                                                    .matchedTransitionSource(
                                                        id: event.id,
                                                        in: mainNamespace
                                                    )
                                                    .opacity(newEventIds.contains(event.id) && !animateNewEvents ? 0 : 1)
                                                    .scaleEffect(newEventIds.contains(event.id) && !animateNewEvents ? 0.8 : 1)
                                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNewEvents)
                                                }
                                        }
                                    }
                                }
                                // For single event (could be small, medium, or large)
                                else if let singleEvent = group
                                    .first
                                {
                                    if singleEvent.eventSize == .large {
                                        // Large events get full width
                                        NavigationLink(
                                            destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace)).navigationBarBackButtonHidden(true).toolbar(.hidden)}) {
                                                EventCard(
                                                    event: singleEvent,
                                                    eventSize: singleEvent
                                                        .eventSize
                                                )
                                                .matchedTransitionSource(
                                                    id: singleEvent.id,
                                                    in: mainNamespace
                                                )
                                                .opacity(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0 : 1)
                                                .scaleEffect(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0.8 : 1)
                                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNewEvents)
                                            }
                                    } else {
                                        // For small or medium events, create a layout with appropriate spacing
                                        HStack(spacing: 20) {
                                            if group.first?.position == .right {
                                                // Empty space (nothing) on the left
                                                Spacer()
                                                    .frame(maxWidth: .infinity)

                                                NavigationLink(
                                                    destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace))}) {
                                                        EventCard(
                                                            event: singleEvent,
                                                            eventSize: singleEvent
                                                                .eventSize
                                                        ).padding(.trailing, 15)
                                                        .matchedTransitionSource(
                                                            id: singleEvent.id,
                                                            in: mainNamespace
                                                        )
                                                        .opacity(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0 : 1)
                                                        .scaleEffect(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0.8 : 1)
                                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNewEvents)
                                                    }
                                            } else {
                                                // Event on the left
                                                NavigationLink(
                                                    destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace))}) {
                                                        EventCard(
                                                            event: singleEvent,
                                                            eventSize: singleEvent
                                                                .eventSize
                                                        ).padding(.leading, 15)
                                                        .matchedTransitionSource(
                                                            id: singleEvent.id,
                                                            in: mainNamespace
                                                        )
                                                        .opacity(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0 : 1)
                                                        .scaleEffect(newEventIds.contains(singleEvent.id) && !animateNewEvents ? 0.8 : 1)
                                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateNewEvents)
                                                    }

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
                                .padding(.vertical, 10)
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
//                        HStack(spacing: 20) {
//                            Button(action: {
//                                navigationPath.append("friendSearch")
//                            }) {
//                                ZStack {
//                                    // Background using MenuItem component
//                                    MenuItem(
//                                        mainColor: Color(hex: "#E97451"),
//                                        widthProportion: 0.32,
//                                        heightProportion: 0.16
//                                    )
//
//                                    VStack(alignment: .center, spacing: 6) {
//                                        // Add notification badge to image if we have friend requests
//                                        ZStack {
//                                            Image(systemName: "plus.circle")
//                                                .font(
//                                                    .system(
//                                                        size: 45,
//                                                        weight: .medium)
//                                                )
//                                                .foregroundColor(.primary)
//                                        }
//
//                                        Text("new\nfriend?")
//                                            .font(.pathwaySemiBold(19))
//                                            .foregroundColor(.primary)
//                                            .multilineTextAlignment(.center)
//                                    }
//
//                                    if friendManager.incomingRequests.count > 0
//                                    {
//                                        Text(
//                                            "\(friendManager.incomingRequests.count)"
//                                        )
//                                        .font(.pathwayBoldCondensed(12))
//                                        .foregroundColor(.white)
//                                        .padding(10)
//                                        .background(Color.red)
//                                        .clipShape(Circle())
//                                        .offset(x: 30, y: -50)
//                                    }
//                                }
//                            }.matchedTransitionSource(
//                                id: "friendSearch", in: mainNamespace
//                            )
//                            .buttonStyle(PlainButtonStyle())
//                        }
                    }
                }
                .refreshable {
                    await refreshEventsManually()
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
                default:
                    EmptyView()
                }
            }
        )
        .onAppear {
            currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)

            // On first appear, load friend data and events if needed
            isLoadingFriendData = true
            Task {
                await friendManager.refreshFriendDataBatched()
                await MainActor.run {
                    isLoadingFriendData = false

                    // Only load events on first appear if we don't have any
                    if events.isEmpty {
                        Task {
                            await fetchEvents()
                        }
                    }
                }
            }
        }
    }

    // Function to fetch events from the server
    private func fetchEvents() async {
        guard let user = currentUser else { return }

        // Don't continue if there are no friends
        if friendManager.friends.isEmpty && !isLoadingFriendData {
            return
        }

        // Limit refresh frequency to prevent flickering
        let currentTime = Date()
        let minRefreshInterval: TimeInterval = 30 // Seconds between refreshes

        if currentTime.timeIntervalSince(lastRefreshTime) < minRefreshInterval && !events.isEmpty {
            return // Skip refresh if too recent and we already have events
        }

        lastRefreshTime = currentTime

        if events.isEmpty {
            isLoadingEvents = true
        }

        Task {
            // First, preload all tasks for all friends
            await friendManager.preloadAllFriendTasksBatched()
            var fetchedEvents: [taskapeEvent] = []

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

                    fetchedEvents.append(event)
                }
            }

            await MainActor.run {
                // Identify truly new events for animation - those never seen before
                let incomingIds = Set(fetchedEvents.map { $0.id })
                let trulyNewIds = incomingIds.subtracting(seenEventIds)

                // Update seen events list to include all current events
                seenEventIds.formUnion(incomingIds)

                // Keep track of new events for animation
                newEventIds = trulyNewIds

                // Prepare animation if truly new events exist
                let hasNewEvents = !trulyNewIds.isEmpty
                animateNewEvents = false

                // First update the events array stably
                updateEventsStably(with: fetchedEvents)

                isLoadingEvents = false

                // Start animation for new events after a slight delay
                if hasNewEvents {
                    // Trigger animation after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            animateNewEvents = true
                        }
                    }

                    // Clear newEventIds after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        newEventIds = []
                    }
                }

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

    // Update events array while maintaining stability
    private func updateEventsStably(with newEvents: [taskapeEvent]) {
        // Create a dictionary of existing events for fast lookup
        var existingEventsDict = [String: taskapeEvent]()
        for event in events {
            existingEventsDict[event.id] = event
        }

        // Build a new array that preserves existing events where possible
        var updatedEvents: [taskapeEvent] = []

        // First, add all existing events that are still present
        for newEvent in newEvents {
            if let existingEvent = existingEventsDict[newEvent.id] {
                // Keep the existing event object but update properties if needed
                // This is important to maintain identity and prevent UI rebuilds
                updateEventProperties(existingEvent, from: newEvent)
                updatedEvents.append(existingEvent)
                existingEventsDict.removeValue(forKey: newEvent.id) // Mark as processed
            } else {
                // This is a genuinely new event
                updatedEvents.append(newEvent)
            }
        }

        // Sort the events by creation date (newest first)
        updatedEvents.sort { $0.createdAt > $1.createdAt }

        // Update the events array
        events = updatedEvents
    }

    // Update properties of an existing event from a new one
    private func updateEventProperties(_ target: taskapeEvent, from source: taskapeEvent) {
        // Update only the properties that might change
        target.likesCount = source.likesCount
        target.commentsCount = source.commentsCount
        target.likedByUserIds = source.likedByUserIds

        // For related tasks, update without replacing the array
        // Remove tasks no longer present
        target.relatedTasks.removeAll { task in
            !source.taskIds.contains(task.id)
        }

        // Add new tasks
        for task in source.relatedTasks {
            if !target.relatedTasks.contains(where: { $0.id == task.id }) {
                target.relatedTasks.append(task)
            }
        }
    }

    // MARK: - Improved Layout Algorithm
    private func createLayoutGroups(from events: [taskapeEvent]) -> [[taskapeEvent]] {
        if events.isEmpty {
            return []
        }

        // Sort events by date (newest first)
        let sortedEvents = events.sorted { $0.createdAt > $1.createdAt }

        var fullBlocks: [[taskapeEvent]] = [] // For pairs and large events
        var singleBlocks: [[taskapeEvent]] = [] // For single small/medium events
        var processedIds = Set<String>()

        // First, add all large events (they take full width)
        for event in sortedEvents where event.eventSize == .large {
            fullBlocks.append([event])
            processedIds.insert(event.id)
        }

        // Try to form medium+small pairs first
        for medium in sortedEvents where medium.eventSize == .medium && !processedIds.contains(medium.id) {
            if let small = sortedEvents.first(where: { $0.eventSize == .small && !processedIds.contains($0.id) }) {
                fullBlocks.append([medium, small])
                processedIds.insert(medium.id)
                processedIds.insert(small.id)
            }
        }

        // Then try to form small+small pairs
        let remainingSmall = sortedEvents.filter { $0.eventSize == .small && !processedIds.contains($0.id) }
        for i in stride(from: 0, to: remainingSmall.count, by: 2) {
            if i + 1 < remainingSmall.count {
                fullBlocks.append([remainingSmall[i], remainingSmall[i + 1]])
                processedIds.insert(remainingSmall[i].id)
                processedIds.insert(remainingSmall[i + 1].id)
            }
        }

        // Add remaining single events (medium and small)
        for event in sortedEvents {
            if !processedIds.contains(event.id) {
                singleBlocks.append([event])
                processedIds.insert(event.id)
            }
        }

        // Return full blocks first, then single blocks
        return fullBlocks + singleBlocks
    }

    func setupWidgetSync() {
        if let user = currentUser {
            UserManager.shared.syncTasksWithWidget(context: modelContext)
        }
    }

    // Manually refresh events when user pulls to refresh
    @MainActor
    func refreshEventsManually() async {
        guard !isLoadingEvents else { return }

        // Reset refresh state
        lastRefreshTime = Date()

        // Refresh all data

        // First, refresh friend data
        await friendManager.refreshFriendDataBatched()

        // Then, refresh all friend tasks
        await friendManager.preloadAllFriendTasksBatched()

        // Finally fetch events
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchEvents()
            }
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

//#Preview {
//    do {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try ModelContainer(
//            for: taskapeUser.self, taskapeTask.self, configurations: config)
//
//        let user = taskapeUser(
//            id: UUID().uuidString,
//            handle: "shevlfs",
//            bio: "i am shevlfs",
//            profileImage:
//                "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
//            profileColor: "blue"
//        )
//
//        container.mainContext.insert(user)
//        let task = taskapeTask(
//            id: UUID().uuidString,
//            user_id: user.id,
//            name: "Sample Task",
//            taskDescription: "This is a sample task description",
//            author: "shevlfs",
//            privacy: "private"
//        )
//
//        container.mainContext.insert(task)
//
//        user.tasks.append(task)
//
//        try container.mainContext.save()
//
//        return MainView(
//            eventsUpdated: .constant(false),
//            navigationPath: .constant(NavigationPath())
//        )
//        .modelContainer(container)
//    } catch {
//        return Text("Failed to create preview: \(error.localizedDescription)")
//    }
//}

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
