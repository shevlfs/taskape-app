import CachedAsyncImage
import SwiftData
import SwiftUI

struct FriendSearchView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var searchQuery: String = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var errorMessage: String? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var searchTask: Task<Void, Never>? = nil

    @StateObject private var friendManager = FriendManager.shared

    private let currentUserId = UserManager.shared.currentUserId

    @State private var pendingOperations: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $searchQuery)
                .padding(.horizontal)
                .onChange(of: searchQuery) { _, newValue in

                    searchTask?.cancel()

                    searchTask = Task {
                        if newValue.isEmpty {
                            await fetchAllUsers()
                        } else if newValue.count >= 3 {
                            await performSearch()
                        }
                    }
                }
                .padding(.bottom, 10)

            ScrollView {
                if !friendManager.incomingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("friend requests")
                            .font(.pathwayBold(18))
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(friendManager.incomingRequests, id: \.id) { request in
                            FriendRequestRow(request: request)
                                .padding(.horizontal)
                        }

                        Divider()
                            .padding(.vertical, 10)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.pathway(16))
                        .foregroundColor(.red)
                        .padding()
                } else if searchResults.isEmpty, !isSearching, !searchQuery.isEmpty {
                    Text("no users found matching '\(searchQuery)'")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                        .padding()
                }

                if isSearching {
                    ProgressView()
                        .padding()
                }

                if !searchResults.isEmpty {
                    VStack(alignment: .leading) {
                        Text(searchQuery.isEmpty ? "all users" : "search results")
                            .font(.pathwayBold(18))
                            .padding(.horizontal)
                            .padding(.top, 8)

                        LazyVStack(spacing: 12) {
                            ForEach(searchResults, id: \.id) { user in
                                UserSearchResultRow(
                                    user: user,
                                    isFriend: friendManager.isFriend(user.id),
                                    hasSentRequest: friendManager.hasPendingRequestTo(
                                        user.id),
                                    hasReceivedRequest:
                                    friendManager.hasPendingRequestFrom(user.id),
                                    isCurrentUser: user.id == currentUserId,
                                    isPending: pendingOperations.contains(user.id),
                                    onSendRequest: {
                                        sendFriendRequest(to: user)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
        .onAppear {
            Task {
                await friendManager.refreshFriendDataBatched()
                await fetchAllUsers()
            }
        }.background(Color.clear)
    }

    private func fetchAllUsers() async {
        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            if let results = await searchUsers(query: "") {
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "couldn't load users"
                    isSearching = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error: \(error.localizedDescription)"
                isSearching = false
            }
        }
    }

    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            await fetchAllUsers()
            return
        }

        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            if let results = await searchUsers(query: searchQuery) {
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "search error..."
                    isSearching = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error: \(error.localizedDescription)"
                isSearching = false
            }
        }
    }

    private func sendFriendRequest(to user: UserSearchResult) {
        pendingOperations.insert(user.id)

        Task {
            let success = await friendManager.sendFriendRequest(to: user.id)

            await MainActor.run {
                pendingOperations.remove(user.id)

                if !success {
                    errorMessage =
                        "failed to send friend request to @\(user.handle)"
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @State private var isAccepting: Bool = false
    @State private var isRejecting: Bool = false
    @ObservedObject private var friendManager = FriendManager.shared

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(request.sender_handle)")
                    .font(.pathwayBlack(16))

                Text("wants to be your friend")
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                acceptFriendRequest()
            }) {
                if isAccepting {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Text("accept")
                        .font(.pathway(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(16)
                }
            }
            .disabled(isAccepting || isRejecting)

            Button(action: {
                rejectFriendRequest()
            }) {
                if isRejecting {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Text("reject")
                        .font(.pathway(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(16)
                }
            }
            .disabled(isAccepting || isRejecting)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private func acceptFriendRequest() {
        isAccepting = true

        Task {
            let success = await friendManager.acceptFriendRequest(request.id)

            await MainActor.run {
                isAccepting = false

                if success {
                    Task {
                        await friendManager.refreshFriendDataBatched()
                    }
                }
            }
        }
    }

    private func rejectFriendRequest() {
        isRejecting = true

        Task {
            let success = await friendManager.rejectFriendRequest(request.id)

            await MainActor.run {
                isRejecting = false

                if success {
                    Task {
                        await friendManager.refreshFriendDataBatched()
                    }
                }
            }
        }
    }
}

struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
                    .frame(width: 40, alignment: .leading)

                Spacer()

                TextField("", text: $text)
                    .placeholder(when: text.isEmpty && !isFocused) {
                        Text("friend's @")
                            .foregroundColor(.gray)
                            .font(.pathwayBlack(16))
                    }
                    .accentColor(Color.taskapeOrange)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .multilineTextAlignment(.center)
                    .font(.pathwayBlack(16))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .frame(maxWidth: .infinity)

                Spacer()

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                    .frame(width: 40, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(width: 40)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 56)
        .padding(.horizontal)
    }
}

extension View {
    func placeholder(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> some View
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct UserSearchResultRow: View {
    @Environment(\.modelContext) private var modelContext

    let user: UserSearchResult
    let isFriend: Bool
    let hasSentRequest: Bool
    let hasReceivedRequest: Bool
    let isCurrentUser: Bool
    let isPending: Bool
    let onSendRequest: () -> Void

    @State private var showDetail = false
    @State private var isLoadingUserProfile = false
    @State private var userProfile: taskapeUser? = nil
    @State private var loadingError: String? = nil

    @State private var isAccepting: Bool = false

    @ObservedObject private var friendManager = FriendManager.shared

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(
                imageUrl: user.profile_picture,
                color: user.color,
                size: 50
            )
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.handle)")
                    .font(.pathwayBlack(16))

                if isCurrentUser {
                    Text("that's you!")
                        .font(.pathwayItalic(14))
                        .foregroundColor(.secondary)
                } else if isFriend {
                    Text("already friends")
                        .font(.pathwayItalic(14))
                        .foregroundColor(.green)
                } else if hasSentRequest {
                    Text("request sent")
                        .font(.pathwayItalic(14))
                        .foregroundColor(Color.taskapeOrange)
                } else if hasReceivedRequest {
                    Text("request received")
                        .font(.pathwayItalic(14))
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            if !isCurrentUser, !isFriend, !hasSentRequest,
               !hasReceivedRequest
            {
                Button(action: onSendRequest) {
                    if isPending {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.taskapeOrange)
                            .clipShape(Circle())
                    }
                }
                .disabled(isPending)
            } else if hasReceivedRequest {
                Button(action: {
                    acceptFriendRequest()
                }) {
                    if isAccepting {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else if !isFriend {
                        Text("accept")
                            .font(.pathway(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(16)
                    }
                }
                .disabled(isAccepting)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    VStack {
                        if isLoadingUserProfile {
                            ProgressView().padding()
                        } else if let error = loadingError {
                            Text(error)
                                .font(.pathway(14))
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            EmptyView()
                        }
                    }
                )
        )
        .onTapGesture {
            loadUserProfile()
        }
        .sheet(isPresented: $showDetail) {
            if let profile = userProfile {
                UserProfileView(userId: user.id).modelContext(modelContext)
            }
        }
    }

    private func loadUserProfile() {
        guard !isLoadingUserProfile else { return }

        loadingError = nil
        isLoadingUserProfile = true

        print("Loading profile for user: \(user.handle) (ID: \(user.id))")

        Task {
            if let loadedUser = await fetchUser(userId: user.id) {
                print("Successfully loaded profile for \(loadedUser.handle)")

                let userTasks = await fetchTasks(userId: user.id)

                if let tasks = userTasks {
                    print(
                        "Loaded \(tasks.count) visible tasks for \(loadedUser.handle)"
                    )

                    await MainActor.run {
                        let tempContext = ModelContext(
                            ModelContainer.shared.mainContext.container)

                        loadedUser.tasks = tasks

                        tempContext.insert(loadedUser)

                        userProfile = loadedUser
                        isLoadingUserProfile = false
                        showDetail = true
                    }
                } else {
                    print(
                        "No tasks loaded or accessible for \(loadedUser.handle)"
                    )

                    await MainActor.run {
                        let tempContext = ModelContext(
                            ModelContainer.shared.mainContext.container)

                        loadedUser.tasks = []
                        tempContext.insert(loadedUser)

                        userProfile = loadedUser
                        isLoadingUserProfile = false
                        showDetail = true
                    }
                }
            } else {
                print("Failed to load profile for user ID: \(user.id)")

                await MainActor.run {
                    loadingError = "Couldn't load profile"
                    isLoadingUserProfile = false
                }
            }
        }
    }

    private func acceptFriendRequest() {
        isAccepting = true

        Task {
            if let requestId = findFriendRequestId() {
                let success = await friendManager.acceptFriendRequest(requestId)

                await MainActor.run {
                    isAccepting = false

                    if success {
                        Task {
                            await friendManager.refreshFriendDataBatched()
                        }
                    }
                }
            } else {
                await MainActor.run {
                    isAccepting = false
                }
            }
        }
    }

    private func findFriendRequestId() -> String? {
        friendManager.incomingRequests.first(where: {
            $0.sender_id == user.id
        })?.id
    }
}

#Preview {
    FriendSearchView()
        .modelContainer(for: [taskapeUser.self], inMemory: true)
}
