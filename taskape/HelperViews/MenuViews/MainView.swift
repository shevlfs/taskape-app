import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentUser: taskapeUser?
    @Namespace var mainNamespace

    @Binding var eventsUpdated: Bool


    @State private var events: [taskapeEvent] = []
    @State private var isLoadingEvents: Bool = false
    @State private var lastRefreshTime: Date = Date().addingTimeInterval(-60)
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

                        if isLoadingEvents && events.isEmpty {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 16)
                            }
                        }

                        if !events.isEmpty {

                            let chunkedEvents = createLayoutGroups(
                                from: events)

                            ForEach(
                                0..<chunkedEvents.count, id: \.self
                            ) { index in
                                let group = chunkedEvents[index]


                                if group.count == 2 {
                                    HStack(spacing: 20) {
                                        ForEach(group) { event in
                                            NavigationLink(
                                                destination: {EventCardDetailedView(event: event).modelContext(modelContext)}) {
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
                                            destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext).navigationBarBackButtonHidden(true).toolbar(.hidden)}) {
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
                                                    destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext)}) {
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
                                                    destination: {EventCardDetailedView(event: singleEvent).modelContext(modelContext)}) {
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
                        } else if events.isEmpty && !isLoadingEvents {

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


                            Button(action: {
                                navigationPath.append("friendSearch")
                            }) {
                                ZStack {

                                    MenuItem(
                                        mainColor: Color(hex: "#E97451"),
                                        widthProportion: 0.32,
                                        heightProportion: 0.16
                                    )

                                    VStack(alignment: .center, spacing: 6) {

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
                }
                .refreshable {
                    await refreshEventsManually()
                }
                .fadeOutTop(fadeLength: 10)
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
                    EmptyView()
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


        if friendManager.friends.isEmpty && !isLoadingFriendData {
            return
        }


        let currentTime = Date()
        let minRefreshInterval: TimeInterval = 30

        if currentTime.timeIntervalSince(lastRefreshTime) < minRefreshInterval && !events.isEmpty {
            return
        }

        lastRefreshTime = currentTime

        if events.isEmpty {
            isLoadingEvents = true
        }

        Task {

            await friendManager.preloadAllFriendTasks()
            var fetchedEvents: [taskapeEvent] = []

            if let userEvents = await taskape.fetchEvents(userId: user.id) {

                let friendIds = friendManager.friends.map { $0.id }


                var latestEventByFriend: [String: taskapeEvent] = [:]


                for event in userEvents {

                    if friendIds.contains(event.userId) {

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

                let incomingIds = Set(fetchedEvents.map { $0.id })
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


    private func createLayoutGroups(from events: [taskapeEvent])
        -> [[taskapeEvent]]
    {
        var result: [[taskapeEvent]] = []
        var currentIndex = 0

        while currentIndex < events.count {
            let event = events[currentIndex]

            switch event.eventSize {
            case .large:

                result.append([event])
                currentIndex += 1

            case .medium:

                if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .small
                {

                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else {

                    result.append([event])
                    currentIndex += 1
                }

            case .small:

                if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .medium
                {

                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else if currentIndex + 1 < events.count
                    && events[currentIndex + 1].eventSize == .small
                {

                    result.append([event, events[currentIndex + 1]])
                    currentIndex += 2
                } else {

                    result.append([event])
                    currentIndex += 1
                }

            default:

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


    @MainActor
    func refreshEventsManually() async {
        guard !isLoadingEvents else { return }


        lastRefreshTime = Date()




        await friendManager.refreshFriendData()


        await friendManager.preloadAllFriendTasks()


        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchEvents()
            }
        }
    }
}

extension taskapeEvent {
    var position: EventPosition {


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
