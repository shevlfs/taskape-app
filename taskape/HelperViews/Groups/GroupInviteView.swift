

import SwiftData
import SwiftUI

struct GroupInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var group: taskapeGroup

    @ObservedObject private var groupManager = GroupManager.shared
    @ObservedObject private var friendManager = FriendManager.shared

    @State private var searchQuery = ""
    @State private var selectedFriends: [String] = []
    @State private var pendingInvitations: [String] = []
    @State private var isLoading = false
    @State private var isSending = false
    @State private var showingSuccessAlert = false

    var filteredFriends: [Friend] {
        if searchQuery.isEmpty {
            friendManager.friends
        } else {
            friendManager.friends.filter {
                $0.handle.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)

                    TextField("", text: $searchQuery)
                        .placeholder(when: searchQuery.isEmpty) {
                            Text("search friends")
                                .foregroundColor(.gray)
                                .font(.pathway(16))
                        }
                        .font(.pathway(16))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .padding(10)

                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .stroke(.regularMaterial, lineWidth: 1)
                )
                .padding()

                if !selectedFriends.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedFriends, id: \.self) { friendId in
                                SelectedFriendChip(
                                    friendId: friendId,
                                    onRemove: {
                                        selectedFriends.removeAll { $0 == friendId }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 40)
                    .padding(.bottom, 10)
                }

                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if friendManager.friends.isEmpty {
                    Spacer()
                    Text("no friends to invite")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredFriends, id: \.id) { friend in
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: selectedFriends.contains(friend.id),
                                isPending: pendingInvitations.contains(friend.id),
                                isAlreadyMember: group.members.contains(friend.id),
                                onToggle: { selected in
                                    toggleFriendSelection(friend.id, selected: selected)
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }

                Button(action: {
                    sendInvites()
                }) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    } else {
                        Text("invite \(selectedFriends.count) friends")
                            .font(.pathway(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(selectedFriends.isEmpty ? Color.gray : Color.taskapeOrange)
                )
                .padding()
                .disabled(isSending || selectedFriends.isEmpty)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("invite people").font(.pathway(18))
                }
            }
            .alert("invitations sent", isPresented: $showingSuccessAlert) {
                Button("ok", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("your friends have been invited to join the group")
            }
            .onAppear {
                if friendManager.friends.isEmpty {
                    isLoading = true
                    Task {
                        await friendManager.refreshFriendDataBatched()
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                }
            }
        }
    }

    private func toggleFriendSelection(_ friendId: String, selected: Bool) {
        if selected {
            if !selectedFriends.contains(friendId) {
                selectedFriends.append(friendId)
            }
        } else {
            selectedFriends.removeAll { $0 == friendId }
        }
    }

    private func sendInvites() {
        guard !selectedFriends.isEmpty else { return }

        isSending = true

        Task {
            for friendId in selectedFriends {
                pendingInvitations.append(friendId)

                let success = await groupManager.inviteUserToGroup(groupId: group.id, inviteeId: friendId)

                if success {
                    print("Successfully invited user \(friendId) to group \(group.id)")
                } else {
                    print("Failed to invite user \(friendId) to group \(group.id)")
                }
            }

            await MainActor.run {
                isSending = false
                showingSuccessAlert = true
            }
        }
    }
}

struct SelectedFriendChip: View {
    let friendId: String
    let onRemove: () -> Void

    @ObservedObject private var friendManager = FriendManager.shared

    private var friendName: String {
        friendManager.friends.first(where: { $0.id == friendId })?.handle ?? "unknown"
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("@\(friendName)")
                .font(.pathway(14))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.taskapeOrange.opacity(0.8))
        )
    }
}

struct FriendSelectionRow: View {
    let friend: Friend
    let isSelected: Bool
    let isPending: Bool
    let isAlreadyMember: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(
                imageUrl: friend.profile_picture,
                color: friend.color,
                size: 40
            )
            .frame(width: 40, height: 40)

            Text("@\(friend.handle)")
                .font(.pathway(16))

            Spacer()

            if isAlreadyMember {
                Text("already in group")
                    .font(.pathwayItalic(14))
                    .foregroundColor(.secondary)
            } else if isPending {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: {
                    onToggle(!isSelected)
                }) {
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.taskapeOrange : Color.gray.opacity(0.5),
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color.taskapeOrange)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isAlreadyMember)
            }
        }
        .padding(.vertical, 8)
        .opacity(isAlreadyMember ? 0.6 : 1.0)
    }
}
