

import SwiftData
import SwiftUI

struct EventCardCompact: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var event: taskapeEvent
    @Bindable var user: taskapeUser
    @Namespace var namespace

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

    func getTextColor() -> Color {
        Color(hex: user.profileColor).contrastingTextColor(
            in: colorScheme)
    }

    var body: some View {
        NavigationLink(destination: {
            EventCardDetailedView(
                event: event
            )
            .modelContext(modelContext).navigationTransition(
                .zoom(sourceID: event.id, in: namespace))
        }
        ) {
            if event.expiresAt! > Date() {
                VStack(alignment: .center) {
                    VStack {
                        ForEach(event.relatedTasks.prefix(2), id: \.self) {
                            task in

                            Text("• \(task.name)").font(.pathway(13))
                                .minimumScaleFactor(0.01)
                        }

                        if event.relatedTasks.count > 2 {
                            Text("& \(event.relatedTasks.count - 2) more").font(
                                .pathwaySemiBold(12))
                        }
                    }.padding(.top, 10)

                    Spacer()

                    HStack {
                        Text("\(event.createdAt.formatted())").font(
                            .pathwaySemiBold(12)
                        ).multilineTextAlignment(.center)

                        Spacer()

                        Text("\(getEventTypeText())")
                            .font(.pathwaySemiBold(12))
                            .multilineTextAlignment(.center).foregroundColor(
                                getTextColor())

                    }.padding(.horizontal)
                }.padding().foregroundColor(getTextColor()).background(
                    RoundedRectangle(cornerRadius: 20).fill(
                        Color(hex: user.profileColor)
                            .opacity(0.75)
                    ).frame(width: 260, height: 150)
                ).frame(width: 260, height: 150).matchedTransitionSource(
                    id: event.id,
                    in: namespace
                ).shadow(color: .secondary, radius: 2, x: 0, y: 2).padding(
                    .vertical, 5
                )
            } else {
                VStack(alignment: .center) {
                    VStack {
                        ForEach(event.relatedTasks.prefix(2), id: \.self) {
                            task in

                            Text("• \(task.name)").font(.pathway(13))
                                .minimumScaleFactor(0.01)
                        }

                        if event.relatedTasks.count > 2 {
                            Text("& \(event.relatedTasks.count - 2) more").font(
                                .pathwaySemiBold(12))
                        }
                    }.padding(.top, 10)

                    Spacer()

                    Text("expired").font(.pathwaySemiBold(12)).padding(
                        .bottom, 5)

                    HStack {
                        Text("\(event.createdAt.formatted())").font(
                            .pathwaySemiBold(12)
                        ).multilineTextAlignment(.center)

                        Spacer()

                        Text("\(getEventTypeText())")
                            .font(.pathwaySemiBold(12))
                            .multilineTextAlignment(.center).foregroundColor(
                                getTextColor())

                    }.padding(.horizontal)
                }.padding().foregroundColor(getTextColor()).background(
                    RoundedRectangle(cornerRadius: 20).fill(
                        Color(UIColor.systemGray4)
                            .opacity(0.75)
                    ).frame(width: 260, height: 150)
                ).frame(width: 260, height: 150).matchedTransitionSource(
                    id: event.id,
                    in: namespace
                ).shadow(color: .secondary, radius: 2, x: 0, y: 2).padding(
                    .vertical, 5
                )
            }
        }
    }
}

struct EventCardCompactPreview: View {
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
        event.relatedTasks = []
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
            taskIds: [figmaTask.id, figmaTask.id, figmaTask.id]
        )
        event.user = shevlfsUser
        event.relatedTasks = [figmaTask, designTask, uiTask]
        return event
    }

    var body: some View {
        EventCardCompact(event: shevlfsEvent, user: shevlfsUser)
    }
}

#Preview {
    EventCardCompactPreview()
}
