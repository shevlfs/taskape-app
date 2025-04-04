import CachedAsyncImage
import SwiftData
import SwiftUI

struct UserSelfProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let userId: String
    @State private var user: taskapeUser?
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isRefreshingTasks = false

    @State var userEvents: [taskapeEvent] = []

    @State private var showEditProfileView: Bool = false

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
                    VStack(spacing: 0) {
                        VStack {
                            VStack(alignment: .center, spacing: 16) {
                                VStack {
                                    ZStack {
                                        HStack {
                                            Button(action: {
                                                dismiss()
                                            }) {
                                                Image(
                                                    systemName: "chevron.left"
                                                )
                                                .font(.pathwayBold(20))
                                                .foregroundColor(.primary)
                                            }
                                            Spacer()
                                            Button(action: {
                                                showEditProfileView.toggle()
                                            }) {
                                                Image(systemName: "pencil")
                                                    .font(.pathwayBold(20))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding()
                                        .padding(.top, 10)
                                    }
                                    if !user.profileImageURL.isEmpty {
                                        CachedAsyncImage(
                                            url: URL(
                                                string: user.profileImageURL)
                                        ) { phase in
                                            switch phase {
                                            case let .success(image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(
                                                        contentMode: .fill
                                                    )
                                                    .frame(
                                                        width: 125, height: 125
                                                    )
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                Color(
                                                                    hex: user
                                                                        .profileColor
                                                                )
                                                                .contrastingTextColor(
                                                                    in:
                                                                    colorScheme
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                            .shadow(radius: 3)
                                                    )
                                            case .failure:
                                                Image(
                                                    systemName:
                                                    "person.circle.fill"
                                                )
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(
                                                    .white.opacity(0.8))
                                            default:
                                                ProgressView()
                                                    .frame(
                                                        width: 100, height: 100
                                                    )
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(
                                                .white.opacity(0.8))
                                    }
                                }
                                .padding(.top)

                                Text("@\(user.handle)")
                                    .font(.pathwayBlack(25))
                                    .foregroundColor(
                                        Color(hex: user.profileColor)
                                            .contrastingTextColor(
                                                in: colorScheme)
                                    )
                            }
                            .padding(.vertical, 30)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .foregroundColor(Color(hex: user.profileColor))
                                .frame(maxWidth: .infinity, maxHeight: 400)
                                .ignoresSafeArea(edges: .top)
                        )

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

                        StreakAndStatsCard(user: user)
                            .padding(.vertical, user.bio == "" ? 25 : 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(userEvents) { event in
                                    EventCardCompact(event: event, user: user)
                                        .modelContext(modelContext)
                                        .padding(.leading, 12)
                                }
                            }
                        }

                        if !user.tasks.isEmpty {
                            Text("to-do's")
                                .font(.pathwayBold(18))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 15)
                                .padding(.bottom, 5)

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
                .ignoresSafeArea(edges: .top)
                .sheet(isPresented: $showEditProfileView) {
                    ProfileEditView(user: user)
                        .modelContext(modelContext)
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
                    if let events = await fetchUserRelatedEvents(userId: userId) {
                        await MainActor.run {
                            userEvents = events
                            fetchedUser.tasks = tasks
                            loadRelatedTasksForEventsSelf(
                                events: events, existingTasks: tasks
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

struct StreakAndStatsCard: View {
    let user: taskapeUser
    @State private var streak: UserStreak?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("streak")
                    .font(.pathwayBold(18))
                    .foregroundColor(.primary)

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if let streak {
                    HStack(spacing: 10) {
                        Spacer()
                        VStack(alignment: .center, spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.taskapeOrange.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(streak.currentStreak == 0 ? .gray : Color.taskapeOrange)
                            }
                            Text("\(streak.currentStreak)")
                                .font(.pathwayBlack(18))
                                .foregroundColor(.primary)
                            Text("current")
                                .font(.pathway(12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .center, spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.yellow)
                            }
                            Text("\(streak.longestStreak)")
                                .font(.pathwayBlack(18))
                                .foregroundColor(.primary)
                            Text("best")
                                .font(.pathway(12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                } else {
                    Text("complete a task to start your streak!")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()

            Divider()

            HStack(spacing: 0) {
                StatItem(
                    title: "tasks",
                    value: "\(user.tasks.count)",
                    userColor: Color(hex: user.profileColor)
                )
                StatItem(
                    title: "completed",
                    value:
                    "\(user.tasks.filter(\.completion.isCompleted).count)",
                    userColor: Color(hex: user.profileColor)
                )
                StatItem(
                    title: "pending",
                    value:
                    "\(user.tasks.filter { !$0.completion.isCompleted }.count)",
                    userColor: Color(hex: user.profileColor)
                )
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
        )
        .padding(.horizontal)
        .onAppear {
            loadStreak()
        }
    }

    private func loadStreak() {
        isLoading = true
        Task {
            if let fetchedStreak = await getUserStreak(userId: user.id) {
                await MainActor.run {
                    streak = fetchedStreak
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    streak = nil
                    isLoading = false
                }
            }
        }
    }

    private func streakStatusMessage(for streak: UserStreak) -> String {
        if let daysSince = streak.daysSinceLastCompleted {
            if daysSince == 0 {
                "a \(streak.currentStreak) day streak is active!"
            } else if daysSince == 1 {
                "needs to complete a task today to keep their streak!"
            } else {
                "streak was broken \(daysSince) days ago"
            }
        } else {
            "\(streak.currentStreak) day streak!"
        }
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
            bio: "something",
            profileImage:
            "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
            profileColor: "#7A57FE"
        )

        container.mainContext.insert(user)
        try container.mainContext.save()

        return UserSelfProfileView(userId: user.id).modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

struct StreakCard: View {
    @State private var streak: UserStreak?
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("streak")
                .font(.pathwayBold(18))
                .foregroundColor(.primary)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let streak {
                HStack(spacing: 20) {
                    VStack(alignment: .center, spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.taskapeOrange.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.orange)
                        }

                        Text("\(streak.currentStreak)")
                            .font(.pathwayBlack(18))
                            .foregroundColor(.primary)

                        Text("current")
                            .font(.pathway(12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "trophy.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.yellow)
                        }

                        Text("\(streak.longestStreak)")
                            .font(.pathwayBlack(18))
                            .foregroundColor(.primary)

                        Text("best")
                            .font(.pathway(12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                if let daysSince = streak.daysSinceLastCompleted,
                   streak.currentStreak > 0
                {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(daysSince <= 1 ? .orange : .red)
                            .opacity(0.8)

                        Text(streakStatusMessage(for: streak))
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            } else {
                Text("no streak active :(")
                    .font(.pathway(16))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
        )
        .onAppear {
            loadStreak()
        }
    }

    private func loadStreak() {
        isLoading = true

        Task {
            if let streak = await UserManager.shared.getCurrentUserStreak() {
                await MainActor.run {
                    self.streak = streak
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    streak = nil
                    isLoading = false
                }
            }
        }
    }

    private func streakStatusMessage(for streak: UserStreak) -> String {
        if let daysSince = streak.daysSinceLastCompleted {
            if daysSince == 0 {
                "you've completed a task today!"
            } else if daysSince == 1 {
                "complete a task today to keep your streak!"
            } else {
                "your streak was broken \(daysSince) days ago"
            }
        } else {
            "\(streak.currentStreak) day streak!"
        }
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

        return UserSelfProfileView(userId: user.id).modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
