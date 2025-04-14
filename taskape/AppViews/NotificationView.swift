import Alamofire
import SwiftData
import SwiftDotenv
import SwiftUI

struct GetGroupInvitationsResponse: Codable {
    let success: Bool
    let invitations: [GroupInvitation]
    let message: String?
}

func getGroupInvites() async -> [GroupInvitation]? {
    guard let token = UserDefaults.standard.string(forKey: "authToken") else {
        print("No auth token found")
        return nil
    }

    let userId = UserManager.shared.currentUserId

    do {
        let headers: HTTPHeaders = [
            "Authorization": token,
        ]

        let result = await AF.request(
            "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/users/\(userId)/groupInvitations",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(GetGroupInvitationsResponse.self).response

        switch result.result {
        case let .success(response):
            if response.success {
                print(response.invitations)
                return response.invitations
            } else {
                print(
                    "Failed to fetch group invitations: \(response.message ?? "Unknown error")"
                )
                return nil
            }
        case let .failure(error):
            print(
                "Failed to fetch group invitations: \(error.localizedDescription)"
            )
            return nil
        }
    }
}

func createNotificationId(for type: NotificationType, data: Any) -> String {
    switch type {
    case .friendRequest:
        if let request = data as? FriendRequest {
            return "friendreq_\(request.id)"
        }
    case .groupInvite:
        return "groupinv_\(UUID().uuidString)"
    case .deadline:
        if let task = data as? taskapeTask {
            return "deadline_\(task.id)"
        }
    case .confirmationRequest:
        if let task = data as? taskapeTask {
            return "confirm_\(task.id)"
        }
    case .eventLike:
        if let event = data as? taskapeEvent {
            return "like_\(event.id)"
        }
    case .eventComment:
        if let event = data as? taskapeEvent {
            return "comment_\(event.id)"
        }
    }
    return UUID().uuidString
}

class NotificationModel: Identifiable {
    var id: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool = false
    var data: Any

    init(
        id: String? = nil, type: NotificationType, data: Any,
        timestamp: Date = Date()
    ) {
        self.id = id ?? createNotificationId(for: type, data: data)
        self.type = type
        self.data = data
        self.timestamp = timestamp
        isRead = false
    }
}

enum NotificationType {
    case friendRequest
    case groupInvite
    case deadline
    case confirmationRequest
    case eventLike
    case eventComment
}

class NotificationStore: ObservableObject {
    static let shared = NotificationStore()

    @Published var notifications: [NotificationModel] = []
    @Published var isLoading: Bool = false

    private let readNotificationsKey = "ReadNotificationsKey"
    private let lastRefreshTimeKey = "LastNotificationRefreshTimeKey"

    private func getReadNotificationIds() -> Set<String> {
        if let savedIds = UserDefaults.standard.array(
            forKey: readNotificationsKey) as? [String]
        {
            return Set(savedIds)
        }
        return []
    }

    private func saveReadNotificationIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: readNotificationsKey)
    }

    private var lastRefreshTime: Date? {
        get {
            UserDefaults.standard.object(forKey: lastRefreshTimeKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastRefreshTimeKey)
        }
    }

    @discardableResult
    func markAsRead(_ notification: NotificationModel) -> Bool {
        if let index = notifications.firstIndex(where: {
            $0.id == notification.id
        }) {
            if notifications[index].isRead {
                return false
            }

            notifications[index].isRead = true

            var updatedIds = getReadNotificationIds()
            updatedIds.insert(notification.id)
            saveReadNotificationIds(updatedIds)

            objectWillChange.send()
            return true
        }
        return false
    }

    func markAllAsRead() {
        var updatedIds = getReadNotificationIds()
        var stateChanged = false

        for index in notifications.indices {
            if !notifications[index].isRead {
                notifications[index].isRead = true
                updatedIds.insert(notifications[index].id)
                stateChanged = true
            }
        }

        if stateChanged {
            saveReadNotificationIds(updatedIds)
            objectWillChange.send()

            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func removeNotification(_ notification: NotificationModel) {
        notifications.removeAll { $0.id == notification.id }
        objectWillChange.send()
    }

    func refreshNotifications(
        modelContext: ModelContext, completion: (() -> Void)? = nil
    ) {
        isLoading = true

        Task {
            var newNotifications: [NotificationModel] = []

            await refreshFriendRequests(notifications: &newNotifications)
            await refreshGroupInvites(notifications: &newNotifications)
            refreshDeadlines(
                notifications: &newNotifications, modelContext: modelContext
            )
            refreshConfirmationTasks(
                notifications: &newNotifications, modelContext: modelContext
            )
            await refreshEventNotifications(notifications: &newNotifications)

            newNotifications.sort { $0.timestamp > $1.timestamp }

            let readIds = getReadNotificationIds()
            for notification in newNotifications {
                notification.isRead = readIds.contains(notification.id)
            }

            let unreadCount = newNotifications.filter { !$0.isRead }.count
            UIApplication.shared.applicationIconBadgeNumber = unreadCount

            self.lastRefreshTime = Date()

            await MainActor.run {
                let currentUnreadCount = self.notifications.filter {
                    !$0.isRead
                }.count
                let hasNewUnread = unreadCount > currentUnreadCount

                self.notifications = newNotifications
                self.isLoading = false

                if hasNewUnread {
                    NotificationManager.shared
                        .scheduleLocalNotificationsForUnread(
                            notifications: newNotifications)
                }

                completion?()
            }
        }
    }

    private func refreshFriendRequests(notifications: inout [NotificationModel])
        async
    {
        if let incomingRequests = await getFriendRequests(type: "incoming") {
            for request in incomingRequests {
                notifications.append(
                    NotificationModel(
                        id: "friendreq_\(request.id)",
                        type: .friendRequest,
                        data: request,
                        timestamp: ISO8601DateFormatter().date(
                            from: request.created_at) ?? Date()
                    ))
            }
        }
    }

    private func refreshGroupInvites(notifications: inout [NotificationModel])
        async
    {
        if let groupInvites = await getGroupInvites() {
            for invite in groupInvites {
                notifications.append(
                    NotificationModel(
                        id: "groupinv_\(invite.id)",
                        type: .groupInvite,
                        data: invite,
                        timestamp: ISO8601DateFormatter().date(
                            from: invite.created_at) ?? Date()
                    ))
            }
        }
    }

    private func refreshDeadlines(
        notifications: inout [NotificationModel], modelContext: ModelContext
    ) {
        let tasks = UserManager.shared.getCurrentUserTasks(
            context: modelContext)

        let calendar = Calendar.current
        let now = Date()
        let threeDaysFromNow =
            calendar.date(byAdding: .day, value: 3, to: now) ?? now

        for task in tasks {
            if let deadline = task.deadline, !task.completion.isCompleted {
                if deadline > now, deadline <= threeDaysFromNow {
                    notifications.append(
                        NotificationModel(
                            id: "deadline_\(task.id)",
                            type: .deadline,
                            data: task,
                            timestamp: deadline.addingTimeInterval(-86400)
                        ))
                }
            }
        }
    }

    private func refreshConfirmationTasks(
        notifications: inout [NotificationModel], modelContext: ModelContext
    ) {
        let tasks = UserManager.shared.getCurrentUserTasks(
            context: modelContext)

        for task in tasks {
            if task.completion.requiresConfirmation,
               task.completion.isCompleted, !task.completion.isConfirmed
            {
                notifications.append(
                    NotificationModel(
                        id: "confirm_\(task.id)",
                        type: .confirmationRequest,
                        data: task
                    ))
            }
        }
    }

    private func refreshEventNotifications(
        notifications: inout [NotificationModel]
    ) async {
        let userId = UserManager.shared.currentUserId

        if let events = await fetchEvents(userId: userId) {
            for event in events {
                if event.userId == userId, event.likesCount > 0 {
                    notifications.append(
                        NotificationModel(
                            id: "like_\(event.id)",
                            type: .eventLike,
                            data: event,
                            timestamp: event.createdAt
                        ))
                }

                if event.userId == userId, event.commentsCount > 0 {
                    notifications.append(
                        NotificationModel(
                            id: "comment_\(event.id)",
                            type: .eventComment,
                            data: event,
                            timestamp: event.createdAt
                        ))
                }
            }
        }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func shouldRefreshNotifications() -> Bool {
        guard let lastRefresh = lastRefreshTime else {
            return true
        }

        let timeInterval = Date().timeIntervalSince(lastRefresh)
        return timeInterval > 900
    }
}

struct NotificationView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @StateObject private var notificationStore = NotificationStore.shared
    @ObservedObject private var friendManager = FriendManager.shared

    @State private var pendingOperations: Set<String> = []
    @State private var autoMarkAsRead: Bool = false

    var body: some View {
        ZStack {
            if notificationStore.isLoading {
                ProgressView()
            } else if notificationStore.notifications.isEmpty {
                emptyStateView
            } else {
                VStack {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationStore.notifications) {
                                notification in
                                notificationCard(for: notification)
                                    .padding(.horizontal)
                                    .onAppear {}
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .onAppear {
            notificationStore.refreshNotifications(modelContext: modelContext)
            print(notificationStore.notifications)
        }
        .refreshable {
            await refreshNotifications()
        }
    }

    private func refreshNotifications() async {
        await withCheckedContinuation {
            (continuation: CheckedContinuation<Void, Never>) in
            notificationStore.refreshNotifications(modelContext: modelContext) {
                continuation.resume()
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("no notifications")
                .font(.pathwayBold(20))
                .foregroundColor(.primary)

            Text(
                "you're all caught up! there are no notifications to display at this time."
            )
            .font(.pathway(16))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    @ViewBuilder
    private func notificationCard(for notification: NotificationModel)
        -> some View
    {
        switch notification.type {
        case .friendRequest:
            if let request = notification.data as? FriendRequest {
                FriendRequestNotificationCard(
                    request: request,
                    isPending: pendingOperations.contains(request.id),
                    isRead: notification.isRead,
                    onAccept: {
                        handleFriendRequest(
                            request, accept: true, notification: notification
                        )
                    },
                    onReject: {
                        handleFriendRequest(
                            request, accept: false, notification: notification
                        )
                    }
                )
            }
        case .groupInvite:
            if let invitation = notification.data as? GroupInvitation {
                GroupInvitationCard(
                    invitation: invitation,
                    isPending: pendingOperations.contains(invitation.id),
                    isRead: notification.isRead,
                    onAccept: {
                        handleGroupInvitation(
                            invitation, accept: true, notification: notification
                        )
                    },
                    onReject: {
                        handleGroupInvitation(
                            invitation, accept: false,
                            notification: notification
                        )
                    }
                )
            }
        case .deadline:
            if let task = notification.data as? taskapeTask {
                DeadlineNotificationCard(
                    task: task,
                    isRead: notification.isRead
                )
            }
        case .confirmationRequest:
            if let task = notification.data as? taskapeTask {
                ConfirmationTaskCard(
                    task: task,
                    isPending: pendingOperations.contains(task.id),
                    isRead: notification.isRead,
                    onConfirm: {
                        handleTaskConfirmation(
                            task, confirm: true, notification: notification
                        )
                    },
                    onReject: {
                        handleTaskConfirmation(
                            task, confirm: false, notification: notification
                        )
                    }
                )
            }
        case .eventLike:
            if let event = notification.data as? taskapeEvent {
                EventLikeNotificationCard(
                    event: event,
                    isRead: notification.isRead
                )
            }
        case .eventComment:
            if let event = notification.data as? taskapeEvent {
                EventCommentNotificationCard(
                    event: event,
                    isRead: notification.isRead
                )
            }
        }
    }

    private func handleGroupInvitation(
        _ invitation: GroupInvitation, accept: Bool,
        notification: NotificationModel
    ) {
        pendingOperations.insert(invitation.id)

        Task {
            let success: Bool =
                if accept {
                    await GroupManager.shared.acceptGroupInvitation(
                        inviteId: invitation.id)
                } else {
                    await GroupManager.shared.rejectGroupInvitation(
                        inviteId: invitation.id)
                }

            await MainActor.run {
                pendingOperations.remove(invitation.id)

                if success {
                    notificationStore.removeNotification(notification)
                    if accept {
                        Task {
                            await GroupManager.shared.fetchUserGroups(
                                context: modelContext)
                        }
                    }
                }
            }
        }
    }

    private func handleFriendRequest(
        _ request: FriendRequest, accept: Bool, notification: NotificationModel
    ) {
        pendingOperations.insert(request.id)

        Task {
            let success: Bool =
                if accept {
                    await friendManager.acceptFriendRequest(request.id)
                } else {
                    await friendManager.rejectFriendRequest(request.id)
                }

            await MainActor.run {
                pendingOperations.remove(request.id)

                if success {
                    notificationStore.removeNotification(notification)
                }
            }
        }
    }

    private func handleTaskConfirmation(
        _ task: taskapeTask, confirm: Bool, notification: NotificationModel
    ) {
        pendingOperations.insert(task.id)

        Task {
            let confirmerId = UserManager.shared.currentUserId
            let success = await confirmTaskCompletion(
                taskId: task.id,
                confirmerId: confirmerId,
                isConfirmed: confirm
            )

            await MainActor.run {
                pendingOperations.remove(task.id)

                if success {
                    task.completion.isConfirmed = confirm
                    notificationStore.removeNotification(notification)
                }
            }
        }
    }
}

struct FriendRequestNotificationCard: View {
    let request: FriendRequest
    let isPending: Bool
    let isRead: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var senderUser: taskapeUser? = nil

    var body: some View {
        HStack(spacing: 16) {
            if let user = senderUser {
                ProfileImageView(
                    imageUrl: user.profileImageURL,
                    color: user.profileColor,
                    size: 50
                )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(request.sender_handle)")
                    .font(.pathwayBold(16))

                Text("wants to be your friend")
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
                    .textCase(.lowercase)
            }

            Spacer()

            if isPending {
                ProgressView()
                    .padding(.horizontal, 10)
            } else {
                HStack(spacing: 8) {
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.green))
                    }

                    Button(action: onReject) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.clear, lineWidth: 2
                )
        )
        .onAppear {
            loadSenderUser()
        }
    }

    private func loadSenderUser() {
        Task {
            if let user = await fetchUser(userId: request.sender_id) {
                await MainActor.run {
                    senderUser = user
                }
            }
        }
    }
}

struct GroupInvitationCard: View {
    let invitation: GroupInvitation
    let isPending: Bool
    let isRead: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var inviterUser: taskapeUser? = nil
    @ObservedObject private var groupManager = GroupManager.shared

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        inviterUser != nil
                            ? Color(hex: inviterUser!.profileColor)
                            : Color.taskapeOrange
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.group_name)
                    .font(.pathwayBold(16))
                    .lineLimit(1)

                HStack {
                    Text("invited by")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)

                    Text("@\(invitation.inviter_handle)")
                        .font(.pathwayBold(14))
                }

                Text("group invitation")
                    .font(.pathwayItalic(12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            Spacer()

            if isPending {
                ProgressView()
                    .padding(.horizontal, 10)
            } else {
                HStack(spacing: 8) {
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.green))
                    }

                    Button(action: onReject) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.clear, lineWidth: 2)
        )
        .onAppear {
            loadInviterUser()
        }
    }

    private func loadInviterUser() {
        Task {
            if let user = await fetchUser(userId: invitation.inviter_id) {
                await MainActor.run {
                    inviterUser = user
                }
            }
        }
    }
}

struct DeadlineNotificationCard: View {
    let task: taskapeTask
    let isRead: Bool

    @State private var relatedEvent: taskapeEvent? = nil
    @Environment(\.modelContext) private var modelContext

    private var daysUntilDeadline: Int {
        guard let deadline = task.deadline else { return 0 }

        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let deadlineDay = calendar.startOfDay(for: deadline)

        if let days = calendar.dateComponents(
            [.day], from: now, to: deadlineDay
        ).day {
            return days
        }

        return 0
    }

    private var deadlineText: String {
        let days = daysUntilDeadline

        if days == 0 {
            return "due today"
        } else if days == 1 {
            return "due tomorrow"
        } else {
            return "due in \(days) days"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        daysUntilDeadline == 0
                            ? Color.red
                            : daysUntilDeadline == 1
                            ? Color.orange : Color.taskapeOrange
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.pathwayBold(16))
                    .lineLimit(1)

                HStack {
                    Text(deadlineText)
                        .font(.pathway(14))
                        .foregroundColor(
                            daysUntilDeadline == 0
                                ? .red
                                : daysUntilDeadline == 1 ? .orange : .secondary)

                    if let deadline = task.deadline {
                        Text("(\(formatDate(deadline)))")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                    }
                }

                if relatedEvent != nil {
                    Text("part of an event")
                        .font(.pathwayItalic(12))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if let event = relatedEvent {
                NavigationLink(
                    destination: EventCardDetailedView(event: event)
                        .modelContext(modelContext)
                ) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.clear, lineWidth: 2
                )
        )
        .onAppear {
            checkForRelatedEvents()
        }
    }

    private func checkForRelatedEvents() {
        Task {
            if let events = await fetchEvents(userId: task.user_id) {
                for event in events {
                    if event.taskIds.contains(task.id) {
                        await MainActor.run {
                            relatedEvent = event
                        }
                        break
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct ConfirmationTaskCard: View {
    @Bindable var task: taskapeTask
    let isPending: Bool
    let isRead: Bool
    let onConfirm: () -> Void
    let onReject: () -> Void

    @State private var assignerUser: taskapeUser? = nil
    @State private var relatedEvent: taskapeEvent? = nil
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.taskapeOrange)
                        .frame(width: 50, height: 50)

                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.pathwayBold(16))
                        .lineLimit(1)

                    if let user = assignerUser {
                        HStack {
                            Text("completed by")
                                .font(.pathway(14))
                                .foregroundColor(.secondary)

                            Text("@\(user.handle)")
                                .font(.pathwayBold(14))
                        }
                    }

                    if relatedEvent != nil {
                        Text("part of an event")
                            .font(.pathwayItalic(12))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if let event = relatedEvent {
                    NavigationLink(
                        destination: EventCardDetailedView(event: event)
                            .modelContext(modelContext)
                    ) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if let proofUrl = task.completion.proofURL, !proofUrl.isEmpty {
                Text("proof provided")
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()

                if isPending {
                    ProgressView()
                        .padding()
                } else {
                    Button(action: onConfirm) {
                        Text("confirm")
                            .font(.pathway(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green))
                    }
                    .padding(.trailing, 8)

                    Button(action: onReject) {
                        Text("reject")
                            .font(.pathway(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.red))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.clear, lineWidth: 2
                )
        )
        .onAppear {
            loadAssignerUser()
            checkForRelatedEvents()
        }
    }

    private func loadAssignerUser() {
        Task {
            if let user = await fetchUser(userId: task.author) {
                await MainActor.run {
                    assignerUser = user
                }
            }
        }
    }

    private func checkForRelatedEvents() {
        Task {
            if let events = await fetchEvents(userId: task.user_id) {
                for event in events {
                    if event.taskIds.contains(task.id) {
                        await MainActor.run {
                            relatedEvent = event
                        }
                        break
                    }
                }
            }
        }
    }
}

struct EventLikeNotificationCard: View {
    let event: taskapeEvent
    let isRead: Bool

    @State private var likerUsers: [taskapeUser] = []
    @State private var isLoadingUsers = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)

                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("new likes on your event")
                    .font(.pathwayBold(16))

                if isLoadingUsers {
                    Text("loading...")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                } else if likerUsers.isEmpty {
                    Text(
                        "\(event.likesCount) people liked your \(getEventTypeText(event)) event"
                    )
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
                } else {
                    Text(formatLikerNames())
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            NavigationLink(
                destination: EventCardDetailedView(event: event).modelContext(
                    modelContext)
            ) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.clear, lineWidth: 2
                )
        )
        .onAppear {
            loadLikerUsers()
        }
    }

    private func formatLikerNames() -> String {
        if likerUsers.isEmpty {
            return
                "\(event.likesCount) people liked your \(getEventTypeText(event)) event"
        }

        if likerUsers.count == 1 {
            return
                "@\(likerUsers[0].handle) liked your \(getEventTypeText(event)) event"
        } else if likerUsers.count == 2 {
            return
                "@\(likerUsers[0].handle) and @\(likerUsers[1].handle) liked your \(getEventTypeText(event)) event"
        } else if likerUsers.count == 3 {
            return
                "@\(likerUsers[0].handle), @\(likerUsers[1].handle), and @\(likerUsers[2].handle) liked your \(getEventTypeText(event)) event"
        } else {
            let remainingCount = event.likesCount - 3
            return
                "@\(likerUsers[0].handle), @\(likerUsers[1].handle), @\(likerUsers[2].handle) and \(remainingCount) others liked your \(getEventTypeText(event)) event"
        }
    }

    private func loadLikerUsers() {
        guard !event.likedByUserIds.isEmpty else { return }

        isLoadingUsers = true

        Task {
            let userIds = Array(event.likedByUserIds.prefix(3))

            if let users = await getUsersBatch(userIds: userIds) {
                await MainActor.run {
                    likerUsers = users
                    isLoadingUsers = false
                }
            } else {
                await MainActor.run {
                    isLoadingUsers = false
                }
            }
        }
    }

    private func getEventTypeText(_ event: taskapeEvent) -> String {
        switch event.eventType {
        case .newTasksAdded:
            "new tasks"
        case .newlyReceived:
            "newly received"
        case .newlyCompleted:
            "completed"
        case .requiresConfirmation:
            "confirmation"
        case .nDayStreak:
            "\(event.streakDays) day streak"
        case .deadlineComingUp:
            "deadline"
        }
    }
}

struct EventCommentNotificationCard: View {
    let event: taskapeEvent
    let isRead: Bool

    @State private var commenters: [taskapeUser] = []
    @State private var isLoadingUsers = false
    @State private var comments: [EventComment] = []
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)

                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("new comments on your event")
                    .font(.pathwayBold(16))

                if isLoadingUsers {
                    Text("loading...")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                } else if commenters.isEmpty {
                    Text(
                        "\(event.commentsCount) people commented on your \(getEventTypeText(event)) event"
                    )
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
                } else {
                    Text(formatCommenterNames())
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            NavigationLink(
                destination: EventCardDetailedView(event: event).modelContext(
                    modelContext)
            ) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .opacity(isRead ? 0.7 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.clear, lineWidth: 2
                )
        )
        .onAppear {
            loadCommenters()
        }
    }

    private func formatCommenterNames() -> String {
        if commenters.isEmpty {
            return
                "\(event.commentsCount) people commented on your \(getEventTypeText(event)) event"
        }

        if commenters.count == 1 {
            return
                "@\(commenters[0].handle) commented on your \(getEventTypeText(event)) event"
        } else if commenters.count == 2 {
            return
                "@\(commenters[0].handle) and @\(commenters[1].handle) commented on your \(getEventTypeText(event)) event"
        } else if commenters.count == 3 {
            return
                "@\(commenters[0].handle), @\(commenters[1].handle), and @\(commenters[2].handle) commented on your \(getEventTypeText(event)) event"
        } else {
            let remainingCount = event.commentsCount - 3
            return
                "@\(commenters[0].handle), @\(commenters[1].handle), @\(commenters[2].handle) and \(remainingCount) others commented on your \(getEventTypeText(event)) event"
        }
    }

    private func loadCommenters() {
        isLoadingUsers = true

        Task {
            if let eventComments = await fetchEventComments(
                eventId: event.id, limit: 10
            ) {
                let commenterIds = Array(
                    Set(eventComments.map(\.userId))
                ).prefix(3)

                if let users = await getUsersBatch(
                    userIds: Array(commenterIds))
                {
                    await MainActor.run {
                        commenters = users
                        comments = eventComments
                        isLoadingUsers = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingUsers = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoadingUsers = false
                }
            }
        }
    }

    private func getEventTypeText(_ event: taskapeEvent) -> String {
        switch event.eventType {
        case .newTasksAdded:
            "new tasks"
        case .newlyReceived:
            "newly received"
        case .newlyCompleted:
            "completed"
        case .requiresConfirmation:
            "confirmation"
        case .nDayStreak:
            "\(event.streakDays) day streak"
        case .deadlineComingUp:
            "deadline"
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
            .modelContainer(
                for: [
                    taskapeUser.self, taskapeTask.self, taskapeEvent.self,
                    taskapeGroup.self,
                ], inMemory: true
            )
    }
}
