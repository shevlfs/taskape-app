import CachedAsyncImage
import SwiftData
import SwiftUI

struct UserProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let userId: String
    @State private var user: taskapeUser?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isRefreshingTasks = false
    @State private var userEvents: [taskapeEvent] = []

    private var isCurrentUserProfile: Bool {
        userId == UserManager.shared.currentUserId
    }

    var body: some View {
        if UserManager.shared.isCurrentUser(userId: userId) {
            UserSelfProfileView(userId: userId)
                .modelContext(modelContext)
                .navigationBarBackButtonHidden(true).toolbar(.hidden)
        } else {
            OtherUserProfileView(userId: userId, showBackButton: true)
                .modelContext(modelContext).navigationBarBackButtonHidden(true)
                .toolbar(.hidden)
        }
    }

    private func loadUser() {
        Task {
            if let fetchedUser = await fetchUser(userId: userId) {
                if let tasks = await fetchTasks(userId: userId) {
                    if let events = await fetchUserRelatedEvents(
                        userId: userId
                    ) {
                        await MainActor.run {
                            userEvents = events
                            fetchedUser.tasks = tasks
                            loadRelatedTasksForEvents(
                                events: events,
                                modelContext: modelContext
                            )
                            user = fetchedUser
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            userEvents = []
                            fetchedUser.tasks = tasks
                            user = fetchedUser
                            isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        fetchedUser.tasks = []
                        user = fetchedUser
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "error while loading user profile"
                    isLoading = false
                }
            }
        }
    }

    private func refreshTasks() {
        guard !isCurrentUserProfile, let user else { return }

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

struct OtherUserProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let userId: String
    @State private var user: taskapeUser?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isRefreshingTasks = false
    @State private var userEvents: [taskapeEvent] = []
    @State var showBackButton: Bool = true

    private var isCurrentUserProfile: Bool {
        userId == UserManager.shared.currentUserId
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
            } else if let user {
                ScrollView {
                    VStack {
                        HStack {
                            if showBackButton {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(
                                        systemName: "chevron.left"
                                    )
                                    .font(.pathwayBold(20))
                                    .foregroundColor(.primary)
                                }
                            }
                            Spacer()
                        }.padding().padding(.top, 10)
                        VStack(alignment: .center, spacing: 16) {
                            if !user.profileImageURL.isEmpty {
                                CachedAsyncImage(
                                    url: URL(
                                        string: user.profileImageURL
                                    )
                                ) { phase in
                                    switch phase {
                                    case let .success(image):
                                        image
                                            .resizable()
                                            .aspectRatio(
                                                contentMode: .fill
                                            )
                                            .frame(
                                                width: 125,
                                                height: 125
                                            )
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        Color(
                                                            hex:
                                                            user
                                                                .profileColor
                                                        )
                                                        .contrastingTextColor(
                                                            in:
                                                            colorScheme
                                                        ),
                                                        lineWidth: 1
                                                    )
                                                    .shadow(
                                                        radius: 3)
                                            )
                                    case .failure:
                                        Image(
                                            systemName:
                                            "person.circle.fill"
                                        )
                                        .resizable()
                                        .aspectRatio(
                                            contentMode: .fill
                                        )
                                        .frame(
                                            width: 100, height: 100
                                        )
                                        .foregroundColor(
                                            .white.opacity(0.8))
                                    default:
                                        ProgressView()
                                            .frame(
                                                width: 100,
                                                height: 100
                                            )
                                    }
                                }
                            } else {
                                Image(
                                    systemName: "person.circle.fill"
                                )
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .foregroundColor(
                                    .white.opacity(0.8))
                            }

                            Text("@\(user.handle)")
                                .font(.pathwayBlack(25))
                                .foregroundColor(
                                    Color(hex: user.profileColor)
                                        .contrastingTextColor(
                                            in: colorScheme))
                        }
                        .padding(.vertical, 30)
                    }.background(
                        RoundedRectangle(cornerRadius: 9)
                            .foregroundColor(
                                Color(hex: user.profileColor)
                            )
                            .frame(
                                maxWidth: .infinity, maxHeight: 300
                            ).ignoresSafeArea(edges: .top))

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
                                    .foregroundColor(
                                        .primary.opacity(0.8)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 20)
                            }
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
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
                                        Color(
                                            hex: user.profileColor),
                                        lineWidth: 1
                                    )
                                    .blur(radius: 0.5)
                                )
                            )
                        }
                        .offset(y: -16)
                    }
                    StreakAndStatsCard(user: user)
                        .padding(.vertical, user.bio == "" ? 25 : 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(userEvents) { event in
                                EventCardCompact(
                                    event: event, user: user
                                ).modelContext(modelContext)
                                    .padding(
                                        .leading, 12
                                    )
                            }
                        }
                    }

                    if !user.tasks.isEmpty {
                        Text("to-do's")
                            .font(.pathwayBold(18))
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
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
        Task {
            if let fetchedUser = await fetchUser(userId: userId) {
                if let tasks = await fetchTasks(userId: userId) {
                    if let events = await fetchUserRelatedEvents(
                        userId: userId
                    ) {
                        await MainActor.run {
                            userEvents = events
                            fetchedUser.tasks = tasks
                            loadRelatedTasksForEvents(
                                events: events,
                                modelContext: modelContext
                            )
                            user = fetchedUser
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            userEvents = []
                            fetchedUser.tasks = tasks
                            user = fetchedUser
                            isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        fetchedUser.tasks = []
                        user = fetchedUser
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "error while loading user profile"
                    isLoading = false
                }
            }
        }
    }

    private func refreshTasks() {
        guard !isCurrentUserProfile, let user else { return }

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
    @Bindable var task: taskapeTask
    var onToggleCompletion: (() -> Void)? = nil

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(
                            task.completion.isCompleted ? Color.green :
                                task.completion.requiresConfirmation ? Color.yellow : Color.gray,
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)

                    if task.completion.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        task.completion.isCompleted.toggle()
                    }

                    onToggleCompletion?()
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

struct CustomRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat
    var topTrailingRadius: CGFloat
    var bottomLeadingRadius: CGFloat
    var bottomTrailingRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeading = CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius)
        let topTrailing = CGPoint(
            x: rect.maxX, y: rect.minY + topTrailingRadius
        )
        let bottomTrailing = CGPoint(
            x: rect.maxX, y: rect.maxY - bottomTrailingRadius
        )
        let bottomLeading = CGPoint(
            x: rect.minX, y: rect.maxY - bottomLeadingRadius
        )

        path.move(to: topLeading)

        if topLeadingRadius > 0 {
            path.addArc(
                center: CGPoint(
                    x: rect.minX + topLeadingRadius,
                    y: rect.minY + topLeadingRadius
                ),
                radius: topLeadingRadius,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        }

        if topTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - topTrailingRadius,
                    y: rect.minY + topTrailingRadius
                ),
                radius: topTrailingRadius,
                startAngle: Angle(degrees: 270),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        if bottomTrailingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
            path.addArc(
                center: CGPoint(
                    x: rect.maxX - bottomTrailingRadius,
                    y: rect.maxY - bottomTrailingRadius
                ),
                radius: bottomTrailingRadius,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        if bottomLeadingRadius > 0 {
            path.addLine(
                to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
            path.addArc(
                center: CGPoint(
                    x: rect.minX + bottomLeadingRadius,
                    y: rect.maxY - bottomLeadingRadius
                ),
                radius: bottomLeadingRadius,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
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
            for: taskapeUser.self, taskapeTask.self, configurations: config
        )

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

            if colorScheme == .light, isBlueish {
                threshold = 0.65
            } else if colorScheme == .dark {
                threshold = 0.75
            }

            return luminance > threshold ? Color.black : Color.white
        #else
            return .white
        #endif
    }
}
