import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentUser: taskapeUser?
    @Namespace var mainNamespace

    @Binding var eventsUpdated: Bool

    @State private var events: [taskapeEvent] = []
    @State private var isLoadingEvents: Bool = false
    @State private var lastRefreshTime: Date = .init().addingTimeInterval(-60)
    @State private var newEventIds: Set<String> = []
    @State private var seenEventIds: Set<String> = []

    @State private var animateNewEvents: Bool = false

    @State var showFriendInvitationSheet: Bool = false

    @ObservedObject private var friendManager = FriendManager.shared

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

                        if isLoadingEvents, events.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 16)
                            }
                        }

                        if !events.isEmpty {
                            let chunkedEvents = createLayoutGroups(
                                from: events)

                            ForEach(
                                0 ..< chunkedEvents.count, id: \.self
                            ) { index in
                                let group = chunkedEvents[index]

                                if group.count == 2 {
                                    HStack(spacing: 20) {
                                        ForEach(group) { event in
                                            NavigationLink(
                                                destination: { EventCardDetailedView(event: event).modelContext(modelContext).navigationTransition(.zoom(sourceID: event.id, in: mainNamespace)) })
                                            {
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

                                else if let singleEvent = group
                                    .first
                                {
                                    if singleEvent.eventSize == .large {
                                        NavigationLink(
                                            destination: { EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace)).navigationBarBackButtonHidden(true).toolbar(.hidden) })
                                        {
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
                                        HStack(spacing: 20) {
                                            if group.first?.position == .right {
                                                Spacer()
                                                    .frame(maxWidth: .infinity)

                                                NavigationLink(
                                                    destination: { EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace)) })
                                                {
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
                                                NavigationLink(
                                                    destination: { EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationTransition(.zoom(sourceID: singleEvent.id, in: mainNamespace)) })
                                                {
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

                                                Spacer()
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                        } else if events.isEmpty, !isLoadingEvents {
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
                    }
                }
                .refreshable {
                    await refreshEventsManually()
                }.shadow(
                    color: Color(UIColor.tertiaryLabel),
                    radius: 5,
                    x: 0,
                    y: 2
                )
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
                        .modelContext(modelContext)
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

            isLoadingFriendData = true
            Task {
                await friendManager.refreshFriendDataBatched()
                await MainActor.run {
                    isLoadingFriendData = false

                    if events.isEmpty {
                        Task {
                            await fetchEvents()
                        }
                    }
                }
            }
        }
    }

    private func fetchEvents() async {
        guard let user = currentUser else { return }

        if friendManager.friends.isEmpty, !isLoadingFriendData {
            return
        }

        let currentTime = Date()
        let minRefreshInterval: TimeInterval = 30

        if currentTime.timeIntervalSince(lastRefreshTime) < minRefreshInterval, !events.isEmpty {
            return
        }

        lastRefreshTime = currentTime

        if events.isEmpty {
            isLoadingEvents = true
        }

        Task {
            await friendManager.preloadAllFriendTasksBatched()
            var fetchedEvents: [taskapeEvent] = []

            if let userEvents = await taskape.fetchEvents(userId: user.id) {
                let friendIds = friendManager.friends.map(\.id)

                var latestEventByFriend: [String: taskapeEvent] = [:]

                for event in userEvents {
                    if friendIds.contains(event.userId) {
                        if let existingEvent = latestEventByFriend[event.userId] {
                            if event.createdAt > existingEvent.createdAt {
                                latestEventByFriend[event.userId] = event
                            }
                        } else {
                            latestEventByFriend[event.userId] = event
                        }
                    }
                }

                let filteredEvents = Array(latestEventByFriend.values)

                for event in filteredEvents {
                    if !event.taskIds.isEmpty {
                        let relevantTasks = await friendManager.getTasksByIds(
                            friendId: event.userId,
                            taskIds: event.taskIds
                        )

                        await MainActor.run {
                            for task in relevantTasks {
                                if !event.relatedTasks.contains(where: {
                                    $0.id == task.id
                                }) {
                                    event.relatedTasks.append(task)

                                    modelContext.insert(task)
                                }
                            }
                        }
                    }

                    fetchedEvents.append(event)
                }
            }

            await MainActor.run {
                let incomingIds = Set(fetchedEvents.map(\.id))
                let trulyNewIds = incomingIds.subtracting(seenEventIds)

                seenEventIds.formUnion(incomingIds)

                newEventIds = trulyNewIds

                let hasNewEvents = !trulyNewIds.isEmpty
                animateNewEvents = false

                updateEventsStably(with: fetchedEvents)

                isLoadingEvents = false

                if hasNewEvents {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            animateNewEvents = true
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        newEventIds = []
                    }
                }

                do {
                    try modelContext.save()
                } catch {
                    print("error saving context after loading tasks: \(error)")
                }
            }
            eventsUpdated = true
        }
    }

    private func updateEventsStably(with newEvents: [taskapeEvent]) {
        var existingEventsDict = [String: taskapeEvent]()
        for event in events {
            existingEventsDict[event.id] = event
        }

        var updatedEvents: [taskapeEvent] = []

        for newEvent in newEvents {
            if let existingEvent = existingEventsDict[newEvent.id] {
                updateEventProperties(existingEvent, from: newEvent)
                updatedEvents.append(existingEvent)
                existingEventsDict.removeValue(forKey: newEvent.id)
            } else {
                updatedEvents.append(newEvent)
            }
        }

        updatedEvents.sort { $0.createdAt > $1.createdAt }

        events = updatedEvents
    }

    private func updateEventProperties(_ target: taskapeEvent, from source: taskapeEvent) {
        target.likesCount = source.likesCount
        target.commentsCount = source.commentsCount
        target.likedByUserIds = source.likedByUserIds

        target.relatedTasks.removeAll { task in
            !source.taskIds.contains(task.id)
        }

        for task in source.relatedTasks {
            if !target.relatedTasks.contains(where: { $0.id == task.id }) {
                target.relatedTasks.append(task)
            }
        }
    }

    private func createLayoutGroups(from events: [taskapeEvent]) -> [[taskapeEvent]] {
        if events.isEmpty {
            return []
        }

        let sortedEvents = events.sorted { $0.createdAt > $1.createdAt }

        var fullBlocks: [[taskapeEvent]] = []
        var singleBlocks: [[taskapeEvent]] = []
        var processedIds = Set<String>()

        for event in sortedEvents where event.eventSize == .large {
            fullBlocks.append([event])
            processedIds.insert(event.id)
        }

        for medium in sortedEvents where medium.eventSize == .medium && !processedIds.contains(medium.id) {
            if let small = sortedEvents.first(where: { $0.eventSize == .small && !processedIds.contains($0.id) }) {
                fullBlocks.append([medium, small])
                processedIds.insert(medium.id)
                processedIds.insert(small.id)
            }
        }

        let remainingSmall = sortedEvents.filter { $0.eventSize == .small && !processedIds.contains($0.id) }
        for i in stride(from: 0, to: remainingSmall.count, by: 2) {
            if i + 1 < remainingSmall.count {
                fullBlocks.append([remainingSmall[i], remainingSmall[i + 1]])
                processedIds.insert(remainingSmall[i].id)
                processedIds.insert(remainingSmall[i + 1].id)
            }
        }

        for event in sortedEvents {
            if !processedIds.contains(event.id) {
                singleBlocks.append([event])
                processedIds.insert(event.id)
            }
        }

        return fullBlocks + singleBlocks
    }

    func setupWidgetSync() {
        if let user = currentUser {
            UserManager.shared.syncTasksWithWidget(context: modelContext)
        }
    }

    @MainActor
    func refreshEventsManually() async {
        guard !isLoadingEvents else { return }

        lastRefreshTime = Date()

        await friendManager.refreshFriendDataBatched()

        await friendManager.preloadAllFriendTasksBatched()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await fetchEvents()
            }
        }
    }
}

extension taskapeEvent {
    var position: EventPosition {
        let uuidString = id
        let firstChar = uuidString.first ?? "0"
        return firstChar.asciiValue?.isMultiple(of: 2) == true
            ? .left : .right
    }
}

enum EventPosition {
    case left
    case right
}

extension View {
    func fadeOutTop(fadeLength: CGFloat = 50) -> some View {
        mask(
            VStack(spacing: 0) {
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
