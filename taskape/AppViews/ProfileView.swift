//
//  ProfileView.swift
//  taskape
//
//  Created by shevlfs on 3/25/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

//struct SelfProfileView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @State var user: taskapeUser
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                // Header with colored background
//                ZStack {
//                    RoundedRectangle(cornerRadius: 9)
//                        .foregroundColor(Color(hex: user.profileColor))
//                        .frame(maxWidth: .infinity, maxHeight: 250)
//
//                    VStack(alignment: .center, spacing: 16) {
//                        if !user.profileImageURL.isEmpty {
//                            CachedAsyncImage(
//                                url: URL(string: user.profileImageURL)
//                            ) { phase in
//                                switch phase {
//                                case .success(let image):
//                                    image
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fill)
//                                        .frame(width: 100, height: 100)
//                                        .clipShape(Circle())
//                                        .overlay(
//                                            Circle()
//                                                .stroke(
//                                                    Color(
//                                                        hex: user
//                                                            .profileColor
//                                                    )
//                                                    .contrastingTextColor(
//                                                        in: colorScheme),
//                                                    lineWidth: 1
//                                                )
//                                                .shadow(radius: 3)
//                                        )
//                                case .failure:
//                                    Image(systemName: "person.circle.fill")
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fill)
//                                        .frame(width: 100, height: 100)
//                                        .foregroundColor(.white.opacity(0.8))
//                                default:
//                                    ProgressView()
//                                        .frame(width: 100, height: 100)
//                                }
//                            }
//                        } else {
//                            Image(systemName: "person.circle.fill")
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.white.opacity(0.8))
//                        }
//
//                        // Username with contrasting color
//                        Text("\(user.handle)")
//                            .font(.pathwayBlack(25))
//                            .foregroundColor(
//                                Color(hex: user.profileColor)
//                                    .contrastingTextColor(in: colorScheme))
//                    }
//                    .padding(.vertical, 30)
//                }
//                if user.bio != "" {
//                    ZStack {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("about me")
//                                .font(.pathwayBold(18))
//                                .foregroundColor(.white)
//                                .padding(.top, 30)
//                                .padding(.leading, 16)
//
//                            Text(
//                                user.bio
//                            )
//                            .font(.pathway(16))
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.horizontal, 16)
//                            .padding(.bottom, 20)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .background(
//                            // Use a shape with only bottom corners rounded
//                            CustomRoundedRectangle(
//                                topLeadingRadius: 0, topTrailingRadius: 0,
//                                bottomLeadingRadius: 16,
//                                bottomTrailingRadius: 16
//                            )
//                            .fill(Color.clear)
//                            .overlay(
//                                // Very subtle inner glow instead of a distinct outline
//                                CustomRoundedRectangle(
//                                    topLeadingRadius: 0, topTrailingRadius: 0,
//                                    bottomLeadingRadius: 16,
//                                    bottomTrailingRadius: 16
//                                )
//                                .stroke(
//                                    Color(hex: user.profileColor),
//                                    lineWidth: 1
//                                )
//                                .blur(radius: 0.5)
//                            )
//                        )
//                    }
//                    .offset(y: -16)
//                }
//
//                VStack(alignment: .leading, spacing: 16) {
//
//                    HStack(spacing: 0) {
//                        StatItem(
//                            title: "tasks", value: "\(user.tasks.count)",
//                            userColor: Color(hex: user.profileColor)
//                        )
//
//                        StatItem(
//                            title: "completed",
//                            value:
//                                "\(user.tasks.filter { $0.completion.isCompleted }.count)",
//                            userColor: Color(hex: user.profileColor)
//                        )
//
//                        StatItem(
//                            title: "pending",
//                            value:
//                                "\(user.tasks.filter { !$0.completion.isCompleted }.count)",
//                            userColor: Color(hex: user.profileColor)
//                        )
//                    }
//                    .padding(.vertical, 10)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal)
//
//                Spacer(minLength: 40)
//
//            }
//        }
//        .edgesIgnoringSafeArea(.top)
//    }
//}

struct UserProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let userId: String
    @State private var user: taskapeUser?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isRefreshingTasks = false

    // Flag to track if this is the current user's profile
    private var isCurrentUserProfile: Bool {
        return userId == UserManager.shared.currentUserId
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("loading profile...")
            } else if let error = errorMessage {
                VStack {
                    Text(error)
                        .font(.pathway(16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("go back") {
                        dismiss()
                    }
                    .font(.pathway(16))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.taskapeOrange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            } else if let user = user {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with colored background
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .foregroundColor(Color(hex: user.profileColor))
                                .frame(maxWidth: .infinity, maxHeight: 250)

                            // Profile content on the colored background
                            VStack(alignment: .center, spacing: 16) {
                                // Profile picture
                                if !user.profileImageURL.isEmpty {
                                    CachedAsyncImage(
                                        url: URL(string: user.profileImageURL)
                                    ) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            Color(
                                                                hex: user
                                                                    .profileColor
                                                            )
                                                            .contrastingTextColor(
                                                                in: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                        .shadow(radius: 3)
                                                )
                                        case .failure:
                                            Image(
                                                systemName: "person.circle.fill"
                                            )
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(
                                                .white.opacity(0.8))
                                        default:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                // Username with contrasting color
                                Text("@\(user.handle)")
                                    .font(.pathwayBlack(25))
                                    .foregroundColor(
                                        Color(hex: user.profileColor)
                                            .contrastingTextColor(
                                                in: colorScheme))
                            }
                            .padding(.vertical, 30)
                        }

                        if user.bio != "" {
                            ZStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("about me")
                                        .font(.pathwayBold(18))
                                        .foregroundColor(.primary)
                                        .padding(.top, 30)
                                        .padding(.leading, 16)

                                    Text(user.bio)
                                        .font(.pathway(16))
                                        .foregroundColor(.primary.opacity(0.8))
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    CustomRoundedRectangle(
                                        topLeadingRadius: 0,
                                        topTrailingRadius: 0,
                                        bottomLeadingRadius: 16,
                                        bottomTrailingRadius: 16
                                    )
                                    .fill(Color.clear)
                                    .overlay(
                                        CustomRoundedRectangle(
                                            topLeadingRadius: 0,
                                            topTrailingRadius: 0,
                                            bottomLeadingRadius: 16,
                                            bottomTrailingRadius: 16
                                        )
                                        .stroke(
                                            Color(hex: user.profileColor),
                                            lineWidth: 1
                                        )
                                        .blur(radius: 0.5)
                                    )
                                )
                            }
                            .offset(y: -16)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 0) {
                                // Show tasks count
                                StatItem(
                                    title: "tasks",
                                    value: "\(user.tasks.count)",
                                    userColor: Color(hex: user.profileColor)
                                )

                                // Show completed tasks count
                                StatItem(
                                    title: "completed",
                                    value:
                                        "\(user.tasks.filter { $0.completion.isCompleted }.count)",
                                    userColor: Color(hex: user.profileColor)
                                )

                                // Show pending tasks count
                                StatItem(
                                    title: "pending",
                                    value:
                                        "\(user.tasks.filter { !$0.completion.isCompleted }.count)",
                                    userColor: Color(hex: user.profileColor)
                                )
                            }

                            // Show privacy notice if not user's own profile
                            if !isCurrentUserProfile && user.tasks.isEmpty {
                                Text("no publicly visible tasks...")
                                    .font(.pathwayItalic(16))
                                    .foregroundColor(.secondary)
                                    .frame(
                                        maxWidth: .infinity, alignment: .center
                                    )
                                    .padding(.top, 20)
                            }

                            // Refresh button for other users' profiles
                            //                            if !isCurrentUserProfile {
                            //                                Button(action: refreshTasks) {
                            //                                    Label(
                            //                                        isRefreshingTasks ? "Refreshing..." : "Refresh Tasks",
                            //                                        systemImage: isRefreshingTasks ? "arrow.triangle.2.circlepath" : "arrow.clockwise"
                            //                                    )
                            //                                    .font(.pathway(16))
                            //                                    .frame(maxWidth: .infinity)
                            //                                    .padding(.vertical, 10)
                            //                                    .background(Color(hex: user.profileColor).opacity(0.2))
                            //                                    .cornerRadius(20)
                            //                                }
                            //                                .disabled(isRefreshingTasks)
                            //                                .padding(.horizontal)
                            //                                .padding(.top, 10)
                            //                            }

                        }.padding(.vertical, user.bio == "" ? 25 : 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        // Display tasks if there are any
                        if !user.tasks.isEmpty {
                            Text("to-do's")
                                .font(.pathwayBold(18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 15).padding(.bottom, 5)

                            LazyVStack(spacing: 12) {
                                ForEach(user.tasks) { task in
                                    TaskListItem(task: task)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .edgesIgnoringSafeArea(.top)
            } else {
                Text("User not found")
                    .font(.pathway(16))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadUser()
        }
    }

    private func loadUser() {
        // Check if this is the current user
        if isCurrentUserProfile {
            // Fetch the current user
            let currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)
            self.user = currentUser
            self.isLoading = false
        } else {
            // Fetch another user with privacy-filtered tasks
            Task {
                if let fetchedUser = await fetchUser(userId: userId) {
                    if let tasks = await fetchTasks(userId: userId) {
                        await MainActor.run {
                            fetchedUser.tasks = tasks
                            // Create a temporary user without adding to main context
                            self.user = fetchedUser
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            fetchedUser.tasks = []  // Empty array when no tasks are accessible
                            self.user = fetchedUser
                            self.isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "error while loading user profile"
                        self.isLoading = false
                    }
                }
            }
        }
    }

    private func refreshTasks() {
        guard !isCurrentUserProfile, let user = self.user else { return }

        isRefreshingTasks = true

        Task {
            if let tasks = await fetchTasks(userId: userId) {
                await MainActor.run {
                    user.tasks = tasks
                    isRefreshingTasks = false
                }
            } else {
                await MainActor.run {
                    user.tasks = []
                    isRefreshingTasks = false
                }
            }
        }
    }
}

struct TaskListItem: View {
    @State var task: taskapeTask

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                // Completion status indicator - just checkmark when completed
                if task.completion.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 16, height: 16).background(
                            Circle().stroke(style: StrokeStyle(lineWidth: 0.5))
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20))
                } else if task.completion.requiresConfirmation{
                    Circle().stroke(style: StrokeStyle(lineWidth: 0.5))
                        .foregroundColor(.yellow)
                        .frame(width: 20, height: 20)
                }else {
                    Circle().stroke(style: StrokeStyle(lineWidth: 0.5))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }

                if task.name.isEmpty {
                    Text("unnamed to-do").opacity(0.5)
                        .font(.pathway(16))
                        .strikethrough(task.completion.isCompleted)
                        .foregroundColor(
                            task.completion.isCompleted ? .secondary : .primary)
                } else {
                    Text(task.name)
                        .font(.pathway(16))
                        .strikethrough(task.completion.isCompleted)
                        .foregroundColor(
                            task.completion.isCompleted ? .secondary : .primary)
                }

                Spacer()

                // Deadline if available
                if let deadline = task.deadline {
                    Text(formatDate(deadline))
                        .font(.pathwayItalic(14))
                        .foregroundColor(.secondary)
                        .strikethrough(task.completion.isCompleted)
                }
            }

            if let flagName = task.flagName, !flagName.isEmpty {
                HStack {
                    Spacer()

                    Circle()
                        .fill(Color(hex: task.flagColor ?? "#000000"))
                        .frame(width: 10, height: 10)

                    Text(flagName)
                        .font(.pathway(15))
                        .strikethrough(task.completion.isCompleted)
                        .foregroundColor(
                            task.completion.isCompleted ? .secondary : .primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(task.completion.isCompleted ? 0.7 : 1.0)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    var title: String
    var value: String
    @State var userColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.pathwayBlack(20))
                .foregroundColor(userColor)

            Text(title)
                .font(.pathway(14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

//struct ProfileView: View {
//    @Query private var users: [taskapeUser]
//    @State var userID: Int = 0
//
//    var body: some View {
//        Group {
//            if userID == 0 {
//                SelfProfileView(user: users[userID])
//            } else {
//                UserProfileView(user: users[userID])
//            }
//        }
//    }
//}

struct CustomRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat
    var topTrailingRadius: CGFloat
    var bottomLeadingRadius: CGFloat
    var bottomTrailingRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeading = CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius)
        let topTrailing = CGPoint(
            x: rect.maxX, y: rect.minY + topTrailingRadius)
        let bottomTrailing = CGPoint(
            x: rect.maxX, y: rect.maxY - bottomTrailingRadius)
        let bottomLeading = CGPoint(
            x: rect.minX, y: rect.maxY - bottomLeadingRadius)

        path.move(to: topLeading)

        if topLeadingRadius > 0 {
            path.addArc(
                center: CGPoint(
                    x: rect.minX + topLeadingRadius,
                    y: rect.minY + topLeadingRadius),
                radius: topLeadingRadius,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        if topTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - topTrailingRadius,
                    y: rect.minY + topTrailingRadius),
                radius: topTrailingRadius,
                startAngle: Angle(degrees: 270),
                endAngle: Angle(degrees: 0),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        // Bottom-right corner
        if bottomTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - bottomTrailingRadius,
                    y: rect.maxY - bottomTrailingRadius),
                radius: bottomTrailingRadius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        // Bottom-left corner
        if bottomLeadingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
            path.addArc(
                center: CGPoint(
                    x: rect.minX + bottomLeadingRadius,
                    y: rect.maxY - bottomLeadingRadius),
                radius: bottomLeadingRadius,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, configurations: config)

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio:
                "something",
            profileImage:
                "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
            profileColor: "#7A57FE"
        )

        container.mainContext.insert(user)
        try container.mainContext.save()

        return Text("lol").sheet(isPresented: .constant(true)) {
            UserProfileView(userId: user.id).modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

extension Color {
    func contrastingTextColor(in colorScheme: ColorScheme? = nil) -> Color {
        #if canImport(UIKit)
            let uiColor = UIColor(self)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0

            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b

            let isBlueish = b > 0.6 && b > r * 1.5 && b > g * 1.2

            var threshold = 0.5

            if colorScheme == .light && isBlueish {
                threshold = 0.65
            }
            else if colorScheme == .dark {
                threshold = 0.75
            }

            return luminance > threshold ? Color.black : Color.white
        #else
            return .white
        #endif
    }
}
