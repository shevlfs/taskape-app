//
//  FriendSearchSheet.swift
//  taskape
//
//  Created by shevlfs on 3/24/25.
//

import CachedAsyncImage
import SwiftData
import SwiftUI

struct FriendSearchSheet: View {
    @Query private var currentUser: [taskapeUser]

    @State private var searchQuery: String = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var errorMessage: String? = nil

    // Debounce timer for search
    @State private var searchTask: Task<Void, Never>? = nil

    // ObservedObject to manage friend operations
    @StateObject private var friendManager = FriendManager.shared

    // This will track which users have pending friend request operations
    @State private var pendingOperations: Set<String> = []

    var body: some View {
        VStack {
            // Header
            Text("find your friends!")
                .font(.pathway(24))
                .padding(.top, 20)

            // Search field
            SearchField(text: $searchQuery)
                .padding(.horizontal)
                .onChange(of: searchQuery) { oldValue, newValue in
                    // Cancel any existing search
                    searchTask?.cancel()

                    // Create a new search after a delay
                    searchTask = Task {
                        // Only search if query is at least 3 characters
                        if newValue.count >= 3 {
                            await performSearch()
                        } else if newValue.isEmpty {
                            // Clear results when query is empty
                            searchResults = []
                        }
                    }
                }

            // Status message (error or empty state)
            if let error = errorMessage {
                Text(error)
                    .font(.pathway(16))
                    .foregroundColor(.red)
                    .padding()
            } else if searchResults.isEmpty && !isSearching
                && !searchQuery.isEmpty
            {
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
            
            // Results list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults, id: \.id) { user in
                        UserSearchResultRow(
                            user: user,
                            isFriend: friendManager.isFriend(user.id),
                            hasSentRequest: friendManager.hasPendingRequestTo(
                                user.id),
                            hasReceivedRequest:
                                friendManager.hasPendingRequestFrom(user.id),
                            isCurrentUser: currentUser.first?.id == user.id,
                            isPending: pendingOperations.contains(user.id),
                            onSendRequest: {
                                sendFriendRequest(to: user)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }.padding(.top, 20)

            Spacer()
        }
        .onAppear {
            // Load friend data when sheet appears
            Task {
                await friendManager.refreshFriendData()
            }
        }
    }

    // Function to search for users
    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
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
    let user: UserSearchResult
    let isFriend: Bool
    let hasSentRequest: Bool
    let hasReceivedRequest: Bool
    let isCurrentUser: Bool
    let isPending: Bool
    let onSendRequest: () -> Void

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
        )
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
    FriendSearchSheet()
        .modelContainer(for: [taskapeUser.self], inMemory: true)
}
