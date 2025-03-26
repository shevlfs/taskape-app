import CachedAsyncImage
import SwiftUI

enum FriendCardSize {
    case small
    case medium
    case large
}

struct EventCard: View {
    var event: taskapeEvent
    var friendCardSize: FriendCardSize

    @State private var userName: String = ""
    @State private var userColor: String = "000000"
    @State private var userImage: String = ""
    @State private var isLiked: Bool = false

    // Time formatting
    private let timeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        return timeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private func getEventTypeText() -> String {
        switch event.eventType {
        case .newTasksAdded:
            return "added new tasks"
        case .newlyReceived:
            return "received new tasks"
        case .newlyCompleted:
            return "completed tasks"
        case .requiresConfirmation:
            return "needs task confirmation"
        case .nDayStreak:
            let days = event.streakDays
            return "is on a \(days) day streak!"
        case .deadlineComingUp:
            return "has tasks due soon"
        }
    }

    var body: some View {
        Button(action: {
            // Navigate to event detail view
        }) {
            VStack(alignment: .leading, spacing: 0) {
                switch friendCardSize {
                case .small:
                    smallEventView
                case .medium:
                    mediumEventView
                case .large:
                    largeEventView
                }
            }
            .background(
                EventCardBackGround(
                    friendColor: event.user?.profileColor != nil ?
                        Color(hex: event.user!.profileColor) :
                        Color(hex: userColor),
                    size: friendCardSize
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isLiked = event.isLikedByCurrentUser()

            // Load user data if not available
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

    // Small event view - just shows user and type
    private var smallEventView: some View {
        HStack(spacing: 10) {
            userProfileImage(size: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(event.user?.handle ?? userName)")
                    .font(.pathwayBold(14))
                    .lineLimit(1)

                Text(getEventTypeText())
                    .font(.pathway(12))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }

    // Medium event view - shows user, type, and stats
    private var mediumEventView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                userProfileImage(size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(event.user?.handle ?? userName)")
                        .font(.pathwayBold(16))

                    Text(getEventTypeText())
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatDate(event.createdAt))
                    .font(.pathwayItalic(12))
                    .foregroundColor(.secondary)
            }

            if event.taskIds.count > 0 {
                Text("\(event.taskIds.count) tasks")
                    .font(.pathway(14))
                    .padding(.vertical, 2)
            }

            HStack(spacing: 15) {
                Button(action: {
                    toggleLike()
                }) {
                    Label(
                        "\(event.likesCount)",
                        systemImage: isLiked ? "heart.fill" : "heart"
                    )
                    .font(.pathway(12))
                    .foregroundColor(isLiked ? .red : .primary)
                }
                .buttonStyle(PlainButtonStyle())

                Label(
                    "\(event.commentsCount)",
                    systemImage: "bubble.left"
                )
                .font(.pathway(12))
            }
        }
        .padding(12)
    }

    // Large event view - shows everything
    private var largeEventView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                userProfileImage(size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(event.user?.handle ?? userName)")
                        .font(.pathwayBold(18))

                    Text(getEventTypeText())
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatDate(event.createdAt))
                    .font(.pathwayItalic(14))
                    .foregroundColor(.secondary)
            }

            // Task list if available
            if !event.relatedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(event.relatedTasks.prefix(3)) { task in
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)

                            Text(task.name.isEmpty ? "unnamed task" : task.name)
                                .font(.pathway(14))
                                .lineLimit(1)
                                .foregroundColor(.primary.opacity(0.9))
                        }
                    }

                    if event.relatedTasks.count > 3 {
                        Text("& \(event.relatedTasks.count - 3) more...")
                            .font(.pathwayItalic(12))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
                .padding(.vertical, 4)
            } else if event.taskIds.count > 0 {
                Text("\(event.taskIds.count) tasks")
                    .font(.pathway(14))
                    .padding(.vertical, 2)
            }

            // Streak information if applicable
            if event.eventType == .nDayStreak && event.streakDays > 0 {
                HStack {
                    ForEach(0..<min(event.streakDays, 5), id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                    }

                    if event.streakDays > 5 {
                        Text("+\(event.streakDays - 5)")
                            .font(.pathwayBold(14))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Interaction buttons
            HStack(spacing: 20) {
                Button(action: {
                    toggleLike()
                }) {
                    Label(
                        "\(event.likesCount)",
                        systemImage: isLiked ? "heart.fill" : "heart"
                    )
                    .font(.pathway(14))
                    .foregroundColor(isLiked ? .red : .primary)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    // Navigate to comments
                }) {
                    Label(
                        "\(event.commentsCount)",
                        systemImage: "bubble.left"
                    )
                    .font(.pathway(14))
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
    }

    // Helper function to display user profile image
    private func userProfileImage(size: CGFloat) -> some View {
        Group {
            if let user = event.user, !user.profileImageURL.isEmpty {
                CachedAsyncImage(url: URL(string: user.profileImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Circle()
                            .fill(Color(hex: user.profileColor))
                            .overlay(
                                Text(String(user.handle.prefix(1)).uppercased())
                                    .font(.pathwayBold(size * 0.4))
                                    .foregroundColor(.white)
                            )
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Circle()
                            .fill(Color(hex: user.profileColor))
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else if !userImage.isEmpty {
                CachedAsyncImage(url: URL(string: userImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty, _:
                        Circle()
                            .fill(Color(hex: userColor))
                            .overlay(
                                Text(String(userName.prefix(1)).uppercased())
                                    .font(.pathwayBold(size * 0.4))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(hex: userColor))
                    .overlay(
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.pathwayBold(size * 0.4))
                            .foregroundColor(.white)
                    )
                    .frame(width: size, height: size)
            }
        }
    }

    // Toggle like function
    private func toggleLike() {
        let currentUserId = UserManager.shared.currentUserId
        if isLiked {
            // Unlike the event
            isLiked = false
            if event.likesCount > 0 {
                event.likesCount -= 1
            }
            event.likedByUserIds.removeAll { $0 == currentUserId }

            // Update on server
            Task {
                await unlikeEvent(eventId: event.id, userId: currentUserId)
            }
        } else {
            // Like the event
            isLiked = true
            event.likesCount += 1
            event.likedByUserIds.append(currentUserId)

            // Update on server
            Task {
                await likeEvent(eventId: event.id, userId: currentUserId)
            }
        }
    }
}

// Preview for testing
#Preview {
    VStack(spacing: 20) {
        // Create a sample event for small size
        EventCard(
            event: taskapeEvent(
                id: "event1",
                userId: "user1",
                targetUserId: "user2",
                eventType: .newTasksAdded,
                eventSize: .small,
                createdAt: Date().addingTimeInterval(-3600),
                taskIds: ["task1", "task2"],
                likesCount: 5,
                commentsCount: 2
            ),
            friendCardSize: .small
        )

        // Medium size event
        EventCard(
            event: taskapeEvent(
                id: "event2",
                userId: "user1",
                targetUserId: "user2",
                eventType: .newlyCompleted,
                eventSize: .medium,
                createdAt: Date().addingTimeInterval(-86400),
                taskIds: ["task1", "task2", "task3"],
                likesCount: 12,
                commentsCount: 4
            ),
            friendCardSize: .medium
        )

        // Large size event with streak
        EventCard(
            event: taskapeEvent(
                id: "event3",
                userId: "user3",
                targetUserId: "user3",
                eventType: .nDayStreak,
                eventSize: .large,
                createdAt: Date().addingTimeInterval(-172800),
                taskIds: ["task4", "task5"],
                streakDays: 7,
                likesCount: 25,
                commentsCount: 10
            ),
            friendCardSize: .large
        )
    }
    .padding()
}
