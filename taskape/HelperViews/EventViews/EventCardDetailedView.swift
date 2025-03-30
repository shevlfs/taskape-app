//
//  EventCardDetailedView.swift
//  taskape
//
//  Created by shevlfs on 3/30/25.
//


import CachedAsyncImage
import SwiftData
import SwiftUI

struct EventCardDetailedView: View {
    var event: taskapeEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    
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
    @State private var confirmationAlertType: ConfirmationAlertType = .confirming
    
    enum ConfirmationAlertType {
        case confirming
        case success
        case failure
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with back button
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
                
                // Event owner info
                HStack(spacing: 12) {
                    // Profile picture
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
                                        .font(.system(size: 20 * 0.4, weight: .bold))
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
                if event.eventType == .requiresConfirmation && !confirmationSuccess {
                    ConfirmationSection(
                        isConfirming: $isConfirming,
                        showAlert: $showConfirmationAlert,
                        alertType: $confirmationAlertType,
                        onConfirm: {
                            confirmTask(isConfirmed: true)
                        },
                        onReject: {
                            confirmTask(isConfirmed: false)
                        }
                    )
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
                    
                    // Add comment
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
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 30)
        }
        .alert(isPresented: $showConfirmationAlert) {
            switch confirmationAlertType {
            case .confirming:
                return Alert(
                    title: Text("confirm completion"),
                    message: Text("are you sure you want to confirm this task as completed?"),
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
                    message: Text("failed to confirm task completion. please try again."),
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
            if let fetchedComments = await fetchEventComments(eventId: event.id) {
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
                success = await likeEvent(eventId: event.id, userId: UserManager.shared.currentUserId)
            } else {
                success = await unlikeEvent(eventId: event.id, userId: UserManager.shared.currentUserId)
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
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
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

// MARK: - Supporting Views

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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

struct ConfirmationSection: View {
    @Binding var isConfirming: Bool
    @Binding var showAlert: Bool
    @Binding var alertType: EventCardDetailedView.ConfirmationAlertType
    var onConfirm: () -> Void
    var onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("confirmation needed")
                .font(.pathwayBlack(18))
                .padding(.horizontal)
            
            VStack(spacing: 16) {
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
                                RoundedRectangle(cornerRadius: 20)
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
                                RoundedRectangle(cornerRadius: 20)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
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

// MARK: - Preview
struct EventCardDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample event for preview
        let sampleEvent = createSampleEvent()
        
        return EventCardDetailedView(event: sampleEvent)
            .preferredColorScheme(.dark)
    }
    
    static func createSampleEvent() -> taskapeEvent {
        let event = taskapeEvent(
            id: "event1",
            userId: "user1",
            targetUserId: "user1",
            eventType: .newTasksAdded,
            eventSize: .medium,
            createdAt: Date().addingTimeInterval(-3600),
            taskIds: ["task1", "task2"]
        )
        
        // Add sample tasks
        let task1 = taskapeTask(
            id: "task1",
            name: "Complete project",
            taskDescription: "Finish the UI implementation for the main screen",
            author: "user1",
            privacy: PrivacySettings(level: .everyone)
        )
        
        let task2 = taskapeTask(
            id: "task2",
            name: "Write documentation",
            taskDescription: "Create comprehensive documentation for the API",
            author: "user1",
            privacy: PrivacySettings(level: .everyone)
        )
        task2.completion.isCompleted = true
        
        event.relatedTasks = [task1, task2]
        
        return event
    }
}