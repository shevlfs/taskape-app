//
//  EventCardDetailedView.swift
//  taskape
//
//  Created by shevlfs on 3/30/25.
//

import CachedAsyncImage
import Combine
import SwiftData
import SwiftUI
import UIKit

struct EventCardDetailedView: View {
    var event: taskapeEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @ObservedObject private var kGuardian = KeyboardGuardian(textFieldCount: 1)
    @State private var name = Array<String>.init(repeating: "", count: 3)

    // State variables
    @State private var isLoadingComments: Bool = false
    @State private var comments: [EventComment] = []
    @State private var newCommentText: String = ""
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0

    // User info
    @State private var userName: String = ""
    @State private var userColor: String = "000000"
    @State private var userImage: String = ""

    // For task confirmation
    @State private var isConfirming: Bool = false
    @State private var confirmationSuccess: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @State private var confirmationAlertType: ConfirmationAlertType =
        .confirming

    enum ConfirmationAlertType {
        case confirming
        case success
        case failure
    }

    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()

            Text("event details")
                .font(.pathwayBlack(20))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        VStack(spacing: 15) {
            ScrollView( showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
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
                                        Text(
                                            String(userName.prefix(1))
                                                .uppercased()
                                        )
                                        .font(
                                            .system(
                                                size: 20 * 0.4, weight: .bold)
                                        )
                                        .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.pathwayBlack(18))

                            Text(getEventTypeText())
                                .font(.pathwaySemiBold(14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Time ago
                        Text(timeAgoSinceDate(event.createdAt))
                            .font(.pathway(12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Related tasks
                    if !event.relatedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("related tasks")
                                .font(.pathwayBlack(18))
                                .padding(.horizontal)

                            ForEach(event.relatedTasks) { task in
                                RelatedTaskRow(task: task)
                            }
                        }
                    }

                    // Confirmation UI for requires_confirmation events
                    if event.eventType == .requiresConfirmation
                        && !confirmationSuccess
                    {
                        VStack(alignment: .center, spacing: 12) {
                            // Proof section - Show the proof image and description
                            if let task = event.relatedTasks.first {
                                ProofView(task: task)
                            }

                            ConfirmationButtons(
                                isConfirming: $isConfirming,
                                showAlert: $showConfirmationAlert,
                                alertType: $confirmationAlertType,
                                onConfirm: {
                                    confirmTask(isConfirmed: true)
                                },
                                onReject: {
                                    confirmTask(isConfirmed: false)
                                }
                            ).frame(maxWidth: .infinity)
                        }
                    }

                    // Likes section
                    LikesSection(
                        isLiked: $isLiked,
                        likesCount: $likesCount,
                        onLike: {
                            toggleLike()
                        }
                    )
                    .padding(.horizontal)

                    // Comments section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("comments")
                                .font(.pathwayBlack(18))

                            Spacer()

                            if isLoadingComments {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Text("\(comments.count)")
                                    .font(.pathway(14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        // Comments list
                        if comments.isEmpty && !isLoadingComments {
                            VStack {
                                Text("no comments yet")
                                    .font(.pathway(14))
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                    }
                }.frame(maxHeight:.infinity)
                
            }
            HStack {
                TextField("add a comment...", text: $newCommentText)
                    .font(.pathway(14))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )

                Button(action: {
                    addComment()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(
                            newCommentText.isEmpty ? .gray : .taskapeOrange
                        )
                }
                .disabled(newCommentText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 4).padding(.bottom)

        }

        .navigationBarBackButtonHidden(true).toolbar(.hidden)
        .alert(isPresented: $showConfirmationAlert) {
            switch confirmationAlertType {
            case .confirming:
                return Alert(
                    title: Text("confirm completion"),
                    message: Text(
                        "are you sure you want to confirm this task as completed?"
                    ),
                    primaryButton: .default(Text("confirm")) {
                        confirmTask(isConfirmed: true)
                    },
                    secondaryButton: .cancel(Text("cancel"))
                )
            case .success:
                return Alert(
                    title: Text("success"),
                    message: Text("task completion confirmed successfully."),
                    dismissButton: .default(Text("ok"))
                )
            case .failure:
                return Alert(
                    title: Text("error"),
                    message: Text(
                        "failed to confirm task completion. please try again."),
                    dismissButton: .default(Text("ok"))
                )
            }
        }
        .onAppear {
            loadEventData()
            fetchComments()
            checkLikeStatus()
        }
    }

    private func loadEventData() {
        // Load user data if not available
        if event.user == nil {
            Task {
                if let user = await fetchUser(userId: event.userId) {
                    await MainActor.run {
                        userName = user.handle
                        userColor = user.profileColor
                        userImage = user.profileImageURL
                    }
                }
            }
        } else {
            userName = event.user!.handle
            userColor = event.user!.profileColor
            userImage = event.user!.profileImageURL
        }

        // Set likes count
        likesCount = event.likesCount
    }

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

    private func fetchComments() {
        isLoadingComments = true

        Task {
            if let fetchedComments = await fetchEventComments(eventId: event.id)
            {
                await MainActor.run {
                    comments = fetchedComments
                    isLoadingComments = false
                }
            } else {
                await MainActor.run {
                    isLoadingComments = false
                }
            }
        }
    }

    private func addComment() {
        guard !newCommentText.isEmpty else { return }

        Task {
            let commentText = newCommentText

            // Clear the text field immediately for better UX
            await MainActor.run {
                newCommentText = ""
            }

            if let comment = await addEventComment(
                eventId: event.id,
                userId: UserManager.shared.currentUserId,
                content: commentText
            ) {
                await MainActor.run {
                    comments.append(comment)
                }
            }
        }
    }

    private func checkLikeStatus() {
        isLiked = event.isLikedByCurrentUser()
    }

    private func toggleLike() {
        let wasLiked = isLiked

        // Optimistically update UI
        isLiked.toggle()
        likesCount += isLiked ? 1 : -1

        Task {
            let success: Bool

            if isLiked {
                success = await likeEvent(
                    eventId: event.id, userId: UserManager.shared.currentUserId)
            } else {
                success = await unlikeEvent(
                    eventId: event.id, userId: UserManager.shared.currentUserId)
            }

            if !success {
                // Revert on failure
                await MainActor.run {
                    isLiked = wasLiked
                    likesCount = event.likesCount
                }
            }
        }
    }

    private func confirmTask(isConfirmed: Bool) {
        isConfirming = true

        // Assuming the first task in relatedTasks is the one to confirm
        guard let task = event.relatedTasks.first else {
            isConfirming = false
            confirmationAlertType = .failure
            showConfirmationAlert = true
            return
        }

        Task {
            let success = await confirmTaskCompletion(
                taskId: task.id,
                confirmerId: UserManager.shared.currentUserId,
                isConfirmed: isConfirmed
            )

            await MainActor.run {
                isConfirming = false
                confirmationSuccess = success

                if success {
                    confirmationAlertType = .success
                } else {
                    confirmationAlertType = .failure
                }

                showConfirmationAlert = true
            }
        }
    }

    private func timeAgoSinceDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents(
            [.minute, .hour, .day, .weekOfYear, .month, .year], from: date,
            to: now)

        if let year = components.year, year >= 1 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }

        if let month = components.month, month >= 1 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }

        if let weekOfYear = components.weekOfYear, weekOfYear >= 1 {
            return weekOfYear == 1 ? "1 week ago" : "\(weekOfYear) weeks ago"
        }

        if let day = components.day, day >= 1 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }

        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }

        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }

        return "just now"
    }
}

// MARK: - Proof View

struct ProofView: View {
    var task: taskapeTask

    var body: some View {
        VStack(alignment: .leading) {
            // Proof Description
            VStack(alignment: .leading, spacing: 12){
                if let proofDescription = task.proofDescription,
                   !proofDescription.isEmpty
                {
                    Text("proof description:")
                        .font(.pathwayBold(16))
                        .padding(.horizontal)

                    Text(proofDescription)
                        .font(.pathway(14))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }.padding(.top,10)

            // Proof Image
            if let proofURL = task.completion.proofURL, !proofURL.isEmpty {
                Text("submitted proof:")
                    .font(.pathwayBold(16))
                    .padding(.top, 10).padding(.bottom, 5).padding(.horizontal)

                CachedAsyncImage(url: URL(string: proofURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 500)
                    case .failure:
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("could not load image")
                                .font(.pathway(14))
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    @unknown default:
                        EmptyView()
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20
                            )
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// MARK: - Confirmation Buttons

struct ConfirmationButtons: View {
    @Binding var isConfirming: Bool
    @Binding var showAlert: Bool
    @Binding var alertType: EventCardDetailedView.ConfirmationAlertType
    var onConfirm: () -> Void
    var onReject: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("this task requires confirmation to be marked as complete")
                .font(.pathway(14))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    alertType = .confirming
                    showAlert = true
                }) {
                    Text("confirm")
                        .font(.pathway(16))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.green)
                        )
                }

                Button(action: {
                    onReject()
                }) {
                    Text("reject")
                        .font(.pathway(16))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.red)
                        )
                }
            }
            .disabled(isConfirming)
            .overlay(
                Group {
                    if isConfirming {
                        ProgressView()
                    }
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views (Unchanged)

struct RelatedTaskRow: View {
    var task: taskapeTask

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Task status indicator
            Circle()
                .fill(task.completion.isCompleted ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name.isEmpty ? "unnamed task" : task.name)
                    .font(.pathwayBold(16))
                    .strikethrough(task.completion.isCompleted)

                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

struct LikesSection: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    var onLike: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                onLike()
            }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(isLiked ? .red : .primary)
            }

            Text("\(likesCount)")
                .font(.pathway(14))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            Spacer()
        }
    }
}

struct CommentRow: View {
    var comment: EventComment
    @State private var userName: String = ""
    @State private var userColor: String = "000000"
    @State private var userImage: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
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
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(userName.isEmpty ? "user" : userName)
                        .font(.pathwayBold(14))

                    Spacer()

                    Text(timeAgoText(from: comment.createdAt))
                        .font(.pathway(12))
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.pathway(14))
                    .lineLimit(nil)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .onAppear {
            loadUserData()
        }
    }

    private func loadUserData() {
        Task {
            if let user = await fetchUser(userId: comment.userId) {
                await MainActor.run {
                    userName = user.handle
                    userColor = user.profileColor
                    userImage = user.profileImageURL
                }
            }
        }
    }

    private func timeAgoText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    // Create a sample event with a task requiring confirmation
    let event = createPreviewEvent()

    // Create a SwiftData container for the preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: taskapeEvent.self, taskapeTask.self)

    return EventCardDetailedView(event: event)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

func createPreviewEvent() -> taskapeEvent {
    // Create the event for a task requiring confirmation
    let event = taskapeEvent(
        id: "event1",
        userId: "user1",
        targetUserId: "user1",
        eventType: .requiresConfirmation,
        eventSize: .medium,
        createdAt: Date().addingTimeInterval(-3600),
        taskIds: ["task1"],
        streakDays: 0,
        likesCount: 42,
        commentsCount: 7,
        likedByUserIds: ["current_user_id"]
    )

    // Create a sample task that requires confirmation
    let task = taskapeTask(
        id: "task1",
        user_id: "user1",
        name: "create app documentation",
        taskDescription: "write comprehensive guide for the taskape app",
        author: "user1",
        privacy: PrivacySettings(level: .everyone)
    )

    // Set confirmation-related properties
    task.proofNeeded = true
    task.proofDescription = "please provide a screenshot of the completed documentation"
    task.completion.isCompleted = true
    task.completion.requiresConfirmation = true
    task.completion.proofURL = "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg"

    // Create a sample user
    let user = taskapeUser(
        id: "user1",
        handle: "demouser",
        bio: "this is a demo user",
        profileImage: "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
        profileColor: "FF9500" // Orange color matching the app style
    )

    // Set the current user ID to match a liked user ID for testing like functionality
    UserManager.shared.currentUserId = "current_user_id"

    // Associate the user with the event
    event.user = user

    // Associate the task with the event
    event.relatedTasks = [task]

    return event
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return viewControllers.count > 1
    }
}

struct AdaptsToKeyboard: ViewModifier {
    @State var currentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.currentHeight)
                .onAppear(perform: {
                    NotificationCenter.Publisher(
                        center: NotificationCenter.default,
                        name: UIResponder.keyboardWillShowNotification
                    )
                    .merge(
                        with: NotificationCenter.Publisher(
                            center: NotificationCenter.default,
                            name: UIResponder
                                .keyboardWillChangeFrameNotification)
                    )
                    .compactMap { notification in
                        withAnimation(.easeOut(duration: 0.16)) {
                            notification.userInfo?[
                                UIResponder.keyboardFrameEndUserInfoKey]
                                as? CGRect
                        }
                    }
                    .map { rect in
                        rect.height - geometry.safeAreaInsets.bottom
                    }
                    .subscribe(
                        Subscribers.Assign(
                            object: self, keyPath: \.currentHeight))

                    NotificationCenter.Publisher(
                        center: NotificationCenter.default,
                        name: UIResponder.keyboardWillHideNotification
                    )
                    .compactMap { notification in
                        CGFloat.zero
                    }
                    .subscribe(
                        Subscribers.Assign(
                            object: self, keyPath: \.currentHeight))
                })
        }
    }
}

extension View {
    func adaptsToKeyboard() -> some View {
        return modifier(AdaptsToKeyboard())
    }
}

final class KeyboardGuardian: ObservableObject {
    public var rects: [CGRect]
    public var keyboardRect: CGRect = CGRect()

    // keyboardWillShow notification may be posted repeatedly,
    // this flag makes sure we only act once per keyboard appearance
    public var keyboardIsHidden = true

    @Published var slide: CGFloat = 0

    var showField: Int = 0 {
        didSet {
            updateSlide()
        }
    }

    init(textFieldCount: Int) {
        self.rects = [CGRect](repeating: CGRect(), count: textFieldCount)

    }

    func addObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyBoardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyBoardDidHide(notification:)),
            name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if keyboardIsHidden {
            keyboardIsHidden = false
            if let rect = notification.userInfo?[
                "UIKeyboardFrameEndUserInfoKey"] as? CGRect
            {
                keyboardRect = rect
                updateSlide()
            }
        }
    }

    @objc func keyBoardDidHide(notification: Notification) {
        keyboardIsHidden = true
        updateSlide()
    }

    func updateSlide() {
        if keyboardIsHidden {
            slide = 0
        } else {
            let tfRect = self.rects[self.showField]
            let diff = keyboardRect.minY - tfRect.maxY

            if diff > 0 {
                slide += diff
            } else {
                slide += min(diff, 0)
            }

        }
    }
}
