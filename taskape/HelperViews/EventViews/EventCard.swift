import CachedAsyncImage
import SwiftData
import SwiftUI

struct EventCard: View {
    var event: taskapeEvent
    var eventSize: EventSize

    @State private var userName: String = ""
    @State private var userColor: String = "000000"
    @State private var userImage: String = ""
    @State private var isLiked: Bool = false

    @Environment(\.colorScheme) var colorScheme

    private func getEventTypeText() -> String {
        switch event.eventType {
        case .newTasksAdded:
            return "added new tasks"
        case .newlyReceived:
            return "newly received"
        case .newlyCompleted:
            return "recently completed"
        case .requiresConfirmation:
            return "needs confirmation"
        case .nDayStreak:
            let days = event.streakDays
            return "is on a \(days) day streak!"
        case .deadlineComingUp:
            return "due soon"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                switch eventSize {
                case .small:
                    smallEventView
                case .medium:
                    mediumEventView
                case .large:
                    largeEventView
                }
            }
        }
        .onAppear {
            isLiked = event.isLikedByCurrentUser()

            if event.user == nil {
                Task {
                    if let user = await fetchUser(userId: event.userId) {
                        userName = user.handle
                        userColor = user.profileColor
                        userImage = user.profileImageURL
                    }
                }
            } else {
                userName = event.user!.handle
                userColor = event.user!.profileColor
                userImage = event.user!.profileImageURL
            }
        }
    }

    private var smallEventView: some View {
        ZStack(alignment: .topLeading) {
            EventCardBackGround(
                friendColor: Color(hex: userColor), size: .small
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    CachedAsyncImage(url: URL(string: userImage)) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty, _:
                            Circle()
                                .fill(Color(hex: userColor))
                                .overlay(
                                    Text(
                                        String(userName.prefix(1)).uppercased()
                                    )
                                    .font(
                                        .system(size: 20 * 0.4, weight: .bold)
                                    )
                                    .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
                    .padding(.top, 8)
                }

                Text("\(userName)").minimumScaleFactor(0.01)
                    .font(.pathwayBlack(20))
                    .foregroundColor(getTextColor())
                    .lineLimit(1).minimumScaleFactor(0.01)
                    .padding(.leading, 9).padding(.top, 15).padding(
                        .trailing, 5
                    )
            }
        }.frame(
            width: UIScreen.main.bounds.width * proportions.0,
            height: UIScreen.main.bounds.height * proportions.1
        )
    }

    private var mediumEventView: some View {
        ZStack(alignment: .topLeading) {
            EventCardBackGround(
                friendColor: Color(hex: userColor), size: .medium
            )

            HStack {
                VStack {
                    CachedAsyncImage(url: URL(string: userImage)) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty, _:
                            Circle()
                                .fill(Color(hex: userColor))
                                .overlay(
                                    Text(
                                        String(userName.prefix(1)).uppercased()
                                    )
                                    .font(
                                        .system(size: 20 * 0.4, weight: .bold)
                                    )
                                    .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(Circle())
                    .padding(.leading, 8).padding(.top, 8)
                    Spacer()

                    Text("\(userName)")
                        .font(.pathwayBlack(22))
                        .foregroundColor(getTextColor())
                        .padding(.bottom, 15)
                        .padding(.leading, 5).scaledToFit().frame(
                            maxWidth: .infinity
                        ).minimumScaleFactor(0.01)

                }.padding(.trailing, 8)
                Spacer()
                if !event.relatedTasks.isEmpty {
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(getEventTypeText())")
                            .font(.pathwaySemiBold(11))
                            .lineLimit(2)
                            .foregroundColor(getTextColor())
                            .padding(.bottom, 5)
                            .multilineTextAlignment(.trailing)
                            .allowsTightening(true)
                            .padding(.trailing, 18)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading).padding(.top, 8)

                        VStack {
                            if !event.relatedTasks.isEmpty {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.pathway(11)).foregroundColor(
                                            getTextColor()).minimumScaleFactor(0.01)

                                    Text(event.relatedTasks[0].name)
                                        .foregroundColor(getTextColor())
                                        .font(.pathway(10)).allowsTightening(
                                            true
                                        )
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .padding(
                                            .trailing, 10
                                        ).minimumScaleFactor(0.01)
                                }

                                if event.relatedTasks.count > 1 {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.pathway(11)).foregroundColor(
                                                getTextColor()).minimumScaleFactor(0.01)

                                        Text(event.relatedTasks[1].name)
                                            .foregroundColor(getTextColor())
                                            .font(.pathway(10))
                                            .allowsTightening(
                                                true
                                            ).lineLimit(4).minimumScaleFactor(0.01)
                                            .multilineTextAlignment(.leading)
                                            .padding(.trailing, 10)
                                    }
                                }

                                if event.relatedTasks.count > 2 {
                                    Text("& \(event.relatedTasks.count - 2) more")
                                        .font(.pathwaySemiBold(10))
                                        .foregroundColor(
                                            getTextColor()).minimumScaleFactor(0.01)
                                }
                            }
                        }
                        Spacer()
                    }
                } else {
                    Text(getEventTypeText())
                        .foregroundColor(getTextColor())
                        .font(.pathwaySemiBold(13))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .padding([.trailing])
                }
            }
        }.frame(
            width: UIScreen.main.bounds.width * proportions.0,
            height: UIScreen.main.bounds.height * proportions.1
        )
    }

    private var proportions: (widthProportion: Double, heightProportion: Double) {
        switch eventSize {
        case .small:
            (0.32, 0.16)
        case .medium:
            (0.56, 0.16)
        case .large:
            (0.93, 0.16)
        }
    }

    private var largeEventView: some View {
        ZStack {
            EventCardBackGround(
                friendColor: Color(hex: userColor),
                size: .large
            )

            HStack {
                if !event.relatedTasks.isEmpty {
                    VStack(alignment: .leading) {
                        Text(getEventTypeText())
                            .font(.pathwaySemiBold(16))
                            .foregroundColor(getTextColor())
                            .padding(.top, 12).padding(.leading, 5)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()

                        VStack {
                            if !event.relatedTasks.isEmpty {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.pathway(11)).foregroundColor(
                                            getTextColor()).minimumScaleFactor(0.01)

                                    Text(event.relatedTasks[0].name)
                                        .foregroundColor(getTextColor())
                                        .font(.pathway(11)).allowsTightening(
                                            true
                                        )
                                        .lineLimit(2)
                                        .multilineTextAlignment(.trailing).minimumScaleFactor(0.01)
                                }

                                if event.relatedTasks.count > 1 {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.pathway(11)).foregroundColor(
                                                getTextColor()).minimumScaleFactor(0.01)

                                        Text(event.relatedTasks[1].name)
                                            .foregroundColor(getTextColor())
                                            .font(.pathway(11))
                                            .allowsTightening(
                                                true
                                            ).lineLimit(4)
                                            .multilineTextAlignment(.leading)
                                            .padding(.trailing, 5).minimumScaleFactor(0.01)
                                    }
                                }

                                if event.relatedTasks.count > 2 {
                                    Text("& \(event.relatedTasks.count - 2) more")
                                        .font(.pathwaySemiBold(10))
                                        .foregroundColor(
                                            getTextColor()).minimumScaleFactor(0.01)
                                }
                            }
                        }.padding(.bottom, 10)

                        Spacer()

                    }.padding(.leading, 12)
                } else {
                    VStack {
                        Spacer()
                        Text(getEventTypeText())
                            .foregroundColor(getTextColor())
                            .font(.pathwaySemiBold(16))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }.padding()
                }

                Spacer()
                VStack(alignment: .trailing) {
                    CachedAsyncImage(url: URL(string: userImage)) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty, _:
                            Circle()
                                .fill(Color(hex: userColor))
                                .overlay(
                                    Text(
                                        String(userName.prefix(1)).uppercased()
                                    )
                                    .font(
                                        .system(size: 20 * 0.4, weight: .bold)
                                    )
                                    .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(Circle()).padding(.top)

                    Spacer()

                    Text("\(userName)").minimumScaleFactor(0.01)
                        .font(.pathwayBlack(25))
                        .foregroundColor(getTextColor())
                        .padding(.leading, 17).padding(.bottom, 8).minimumScaleFactor(0.01)

                }.padding(.trailing, 12)
            }

        }.frame(
            width: UIScreen.main.bounds.width * proportions.0,
            height: UIScreen.main.bounds.height * proportions.1
        )
    }

    func getTextColor() -> Color {
        Color(hex: userColor).contrastingTextColor(in: colorScheme)
    }
}

struct EventCardPreview: View {
    let dmitryUser = taskapeUser(
        id: "user1",
        handle: "dmitryddddd",
        bio: "87CEFA",
        profileImage:
        "https://upload.wikimedia.org/wikipedia/en/thumb/5/5f/Original_Doge_meme.jpg/290px-Original_Doge_meme.jpg",
        profileColor: ""
    )
    let gogaUser = taskapeUser(
        id: "user2", handle: "seconduser", bio: "F5F5DC",
        profileImage:
        "https://upload.wikimedia.org/wikipedia/en/thumb/5/5f/Original_Doge_meme.jpg/290px-Original_Doge_meme.jpg",
        profileColor: ""
    )
    let shevlfsUser = taskapeUser(
        id: "user3", handle: "seconduser", bio: "FFC0CB",
        profileImage:
        "https://upload.wikimedia.org/wikipedia/en/thumb/5/5f/Original_Doge_meme.jpg/290px-Original_Doge_meme.jpg",
        profileColor: ""
    )

    let designTask = taskapeTask(
        id: "task1",
        name: "check out this design prototype!",
        taskDescription: "Review the new design prototype",
        author: "goga",
        privacy: "everyone"
    )

    let figmaTask = taskapeTask(
        id: "task2",
        name: "figure out how figma works",
        taskDescription: "Learn Figma basics",
        author: "shevlfs",
        privacy: "everyone"
    )

    let uiTask = taskapeTask(
        id: "task3",
        name: "understand how to make good uis",
        taskDescription: "Study UI design principles",
        author: "shevlfs",
        privacy: "everyone"
    )

    let designChangesTask = taskapeTask(
        id: "task4",
        name: "make some changes to this design",
        taskDescription: "Implement design modifications",
        author: "shevlfs",
        privacy: "everyone"
    )

    var dmitryEvent: taskapeEvent {
        let event = taskapeEvent(
            id: "event1",
            userId: dmitryUser.id,
            targetUserId: dmitryUser.id,
            eventType: .newTasksAdded,
            eventSize: .small,
            createdAt: Date().addingTimeInterval(-3600),
            taskIds: ["task1", "task2"]
        )
        event.user = dmitryUser
        return event
    }

    var gogaEvent: taskapeEvent {
        let event = taskapeEvent(
            id: "event2",
            userId: gogaUser.id,
            targetUserId: gogaUser.id,
            eventType: .newlyCompleted,
            eventSize: .medium,
            createdAt: Date().addingTimeInterval(-86400),
            taskIds: [designTask.id, uiTask.id]
        )
        event.user = gogaUser
        event.relatedTasks = [figmaTask, designTask, uiTask]
        return event
    }

    var shevlfsEvent: taskapeEvent {
        let event = taskapeEvent(
            id: "event3",
            userId: shevlfsUser.id,
            targetUserId: shevlfsUser.id,
            eventType: .newlyReceived,
            eventSize: .large,
            createdAt: Date().addingTimeInterval(-172_800),
            taskIds: [figmaTask.id]
        )
        event.user = shevlfsUser
        event.relatedTasks = [figmaTask, designTask, uiTask]
        return event
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                EventCard(event: dmitryEvent, eventSize: .small)

                EventCard(event: gogaEvent, eventSize: .medium)
            }
            EventCard(event: shevlfsEvent, eventSize: .large)
        }
        .padding()
    }
}

#Preview {
    EventCardPreview()
}
