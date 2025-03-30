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

    // Debounce timer for search
    @State private var searchTask: Task<Void, Never>? = nil

    // ObservedObject to manage friend operations
    @StateObject private var friendManager = FriendManager.shared

    // Current user ID for comparison
    private let currentUserId = UserManager.shared.currentUserId

    // This will track which users have pending friend request operations
    @State private var pendingOperations: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.pathwayBold(20))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("find your friends!")
                    .font(.pathway(24))

                Spacer()
            }.padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Search field
            SearchField(text: $searchQuery)
                .padding(.horizontal)
                .onChange(of: searchQuery) { oldValue, newValue in
                    // Cancel any existing search
                    searchTask?.cancel()

                    // Create a new search after a delay
                    searchTask = Task {
                        if newValue.isEmpty {
                            // Fetch all users when query is empty
                            await fetchAllUsers()
                        } else if newValue.count >= 3 {
                            // Only search if query is at least 3 characters
                            await performSearch()
                        }
                    }
                }
                .padding(.bottom, 10)

            ScrollView {
                // Incoming friend requests section
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

                // Status message (error or empty state)
                if let error = errorMessage {
                    Text(error)
                        .font(.pathway(16))
                        .foregroundColor(.red)
                        .padding()
                } else if searchResults.isEmpty && !isSearching && !searchQuery.isEmpty {
                    Text("no users found matching '\(searchQuery)'")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                        .padding()
                }

                // Loading indicator
                if isSearching {
                    ProgressView()
                        .padding()
                }

                // All users section
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
            // Load friend data and fetch all users when view appears
            Task {
                await friendManager.refreshFriendData()
                await fetchAllUsers()
            }
        }.background(Color.clear)
    }

    // Function to fetch all users (empty search query)
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

    // Function to search for users with a specific query
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

    // Function to send a friend request
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

// Friend Request Row Component
struct FriendRequestRow: View {
    let request: FriendRequest
    @State private var isAccepting: Bool = false
    @State private var isRejecting: Bool = false
    @ObservedObject private var friendManager = FriendManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // We'll fetch the user details from the sender handle
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(request.sender_handle)")
                    .font(.pathwayBlack(16))

                Text("wants to be your friend")
                    .font(.pathway(14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Accept button
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

            // Reject button
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

    // Function to accept friend request
    private func acceptFriendRequest() {
        isAccepting = true

        Task {
            let success = await friendManager.acceptFriendRequest(request.id)

            await MainActor.run {
                isAccepting = false

                if success {
                    // Request is now accepted and will disappear from the list
                    Task {
                        await friendManager.refreshFriendData()
                    }
                }
            }
        }
    }

    // Function to reject friend request
    private func rejectFriendRequest() {
        isRejecting = true

        Task {
            let success = await friendManager.rejectFriendRequest(request.id)

            await MainActor.run {
                isRejecting = false

                if success {
                    // Request is now rejected and will disappear from the list
                    Task {
                        await friendManager.refreshFriendData()
                    }
                }
            }
        }
    }
}

// Custom search field component
struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Background shape
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            // Inner content with proper layout
            HStack {
                // Left icon
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
                    .frame(width: 40, alignment: .leading)

                // Spacer to push text to center
                Spacer()

                // Centered text field
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

                // Trailing spacer
                Spacer()

                // Clear button (only when text is not empty)
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
                    // Empty space to maintain balance when no clear button
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
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// User search result row component
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

    // Add state for tracking accept operations
    @State private var isAccepting: Bool = false

    // Add friend manager to handle accept operations
    @ObservedObject private var friendManager = FriendManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            ProfileImageView(imageUrl: user.profile_picture, color: user.color)
                .frame(width: 50, height: 50)

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.handle)")
                    .font(.pathwayBlack(16))

                // Status text
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

            if !isCurrentUser && !isFriend && !hasSentRequest
                && !hasReceivedRequest
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

    // Function to load the user profile
    private func loadUserProfile() {
        guard !isLoadingUserProfile else { return }

        loadingError = nil
        isLoadingUserProfile = true

        print("Loading profile for user: \(user.handle) (ID: \(user.id))")

        Task {
            // First fetch the user profile
            if let loadedUser = await fetchUser(userId: user.id) {
                print("Successfully loaded profile for \(loadedUser.handle)")

                // Then fetch tasks with the requester_id parameter
                // This will filter tasks based on privacy settings
                let userTasks = await fetchTasks(userId: user.id)

                if let tasks = userTasks {
                    print(
                        "Loaded \(tasks.count) visible tasks for \(loadedUser.handle)"
                    )

                    await MainActor.run {
                        // Create a temporary context to avoid affecting the main one
                        let tempContext = ModelContext(
                            ModelContainer.shared.mainContext.container)

                        // Assign the tasks to the user
                        loadedUser.tasks = tasks

                        // Insert the user into the temp context
                        tempContext.insert(loadedUser)

                        // Set the user profile for the sheet
                        userProfile = loadedUser
                        isLoadingUserProfile = false
                        showDetail = true
                    }
                } else {
                    print(
                        "No tasks loaded or accessible for \(loadedUser.handle)"
                    )

                    await MainActor.run {
                        // Still show the profile even if no tasks are available
                        let tempContext = ModelContext(
                            ModelContainer.shared.mainContext.container)

                        // Initialize with empty tasks array
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

    // Function to accept a friend request
    private func acceptFriendRequest() {
        // Set accepting state to show loader
        isAccepting = true

        Task {
            // Find the request ID from incoming requests
            if let requestId = findFriendRequestId() {
                // Use the friend manager to accept the request
                let success = await friendManager.acceptFriendRequest(requestId)

                await MainActor.run {
                    isAccepting = false

                    // Refresh friend data after acceptance
                    if success {
                        Task {
                            await friendManager.refreshFriendData()
                        }
                    }
                }
            } else {
                // If request ID not found, end accepting state
                await MainActor.run {
                    isAccepting = false
                }
            }
        }
    }

    // Helper function to find the request ID for this user
    private func findFriendRequestId() -> String? {
        return friendManager.incomingRequests.first(where: {
            $0.sender_id == user.id
        })?.id
    }
}

// Profile image component
struct ProfileImageView: View {
    let imageUrl: String
    let color: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))

            if !imageUrl.isEmpty {
                CachedAsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }
        }
    }
}

#Preview {
    FriendSearchView()
        .modelContainer(for: [taskapeUser.self], inMemory: true)
}
