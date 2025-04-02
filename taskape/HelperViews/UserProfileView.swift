//
//  UserProfileView.swift
//  taskape
//
//  Created by shevlfs on 4/2/25.
//

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

    @State private var showEditProfileView: Bool = false

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
                        VStack {
                            VStack(alignment: .center, spacing: 16) {
                                VStack {
                                    ZStack {
                                        HStack {
                                            Button(action: {
                                                dismiss()
                                            }) {
                                                Image(systemName: "chevron.left")
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

                                        }.padding().padding(.top,10)
                                    }
                                    if !user.profileImageURL.isEmpty {
                                        CachedAsyncImage(
                                            url: URL(string: user.profileImageURL)
                                        ) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 125, height: 125)
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
                                }.padding(.top)

                                Text("@\(user.handle)")
                                    .font(.pathwayBlack(25))
                                    .foregroundColor(
                                        Color(hex: user.profileColor)
                                            .contrastingTextColor(
                                                in: colorScheme))
                            }
                            .padding(.vertical, 30)
                        }.background(RoundedRectangle(cornerRadius: 9)
                            .foregroundColor(Color(hex: user.profileColor))
                            .frame(maxWidth: .infinity, maxHeight: 400).ignoresSafeArea(edges: .top))

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

                                StatItem(
                                    title: "tasks",
                                    value: "\(user.tasks.count)",
                                    userColor: Color(hex: user.profileColor)
                                )

                                StatItem(
                                    title: "completed",
                                    value:
                                        "\(user.tasks.filter { $0.completion.isCompleted }.count)",
                                    userColor: Color(hex: user.profileColor)
                                )

                                StatItem(
                                    title: "pending",
                                    value:
                                        "\(user.tasks.filter { !$0.completion.isCompleted }.count)",
                                    userColor: Color(hex: user.profileColor)
                                )
                            }

                            if !isCurrentUserProfile && user.tasks.isEmpty {
                                Text("no publicly visible tasks...")
                                    .font(.pathwayItalic(16))
                                    .foregroundColor(.secondary)
                                    .frame(
                                        maxWidth: .infinity, alignment: .center
                                    )
                                    .padding(.top, 20)
                            }

                        }.padding(.vertical, user.bio == "" ? 25 : 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

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
                }.ignoresSafeArea(edges: .top).sheet(
                    isPresented: $showEditProfileView,
                    content: {
                        ProfileEditView(user: user).modelContext(modelContext)
                    }
                )
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

        if isCurrentUserProfile {

            let currentUser = UserManager.shared.getCurrentUser(
                context: modelContext)
            self.user = currentUser
            self.isLoading = false
        } else {

            Task {
                if let fetchedUser = await fetchUser(userId: userId) {
                    if let tasks = await fetchTasks(userId: userId) {
                        await MainActor.run {
                            fetchedUser.tasks = tasks

                            self.user = fetchedUser
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            fetchedUser.tasks = []
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

        return UserSelfProfileView(userId: user.id).modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
