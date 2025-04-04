

import SwiftData
import SwiftUI

struct GroupMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var group: taskapeGroup

    @ObservedObject private var groupManager = GroupManager.shared

    @State private var members: [GroupMemberViewModel] = []
    @State private var isLoading = false
    @State private var showConfirmRemoval = false
    @State private var memberToRemove: GroupMemberViewModel? = nil

    private var currentUserId: String {
        UserManager.shared.currentUserId
    }

    private var isGroupAdmin: Bool {
        group.isAdmin(userId: currentUserId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if members.isEmpty {
                    Text("no members found")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(members) { member in
                            MemberRow(
                                member: member,
                                isCurrentUser: member.id == currentUserId,
                                isGroupAdmin: isGroupAdmin,
                                onRemove: {
                                    memberToRemove = member
                                    showConfirmRemoval = true
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("group members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                loadMembers()
            }
            .alert("remove member", isPresented: $showConfirmRemoval) {
                Button("cancel", role: .cancel) {
                    memberToRemove = nil
                }

                Button("remove", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
            } message: {
                if let member = memberToRemove {
                    Text("are you sure you want to remove @\(member.handle) from this group?")
                } else {
                    Text("are you sure you want to remove this member from the group?")
                }
            }
        }
    }

    private func loadMembers() {
        isLoading = true

        Task {
            let userBatch = await getUsersBatch(userIds: group.members)

            await MainActor.run {
                if let users = userBatch {
                    members = users.map { user in
                        GroupMemberViewModel(
                            id: user.id,
                            handle: user.handle,
                            profilePicture: user.profileImageURL,
                            color: user.profileColor,
                            isAdmin: group.isAdmin(userId: user.id)
                        )
                    }
                } else {
                    members = []
                }

                isLoading = false
            }
        }
    }

    private func removeMember(_ member: GroupMemberViewModel) {
        guard isGroupAdmin, member.id != currentUserId else { return }

        Task {
            let success = await groupManager.removeUserFromGroup(
                groupId: group.id,
                userId: member.id
            )

            if success {
                await MainActor.run {
                    group.removeMember(userId: member.id)
                    members.removeAll { $0.id == member.id }
                }
            }
        }
    }
}

struct GroupMemberViewModel: Identifiable {
    let id: String
    let handle: String
    let profilePicture: String
    let color: String
    let isAdmin: Bool
}

struct MemberRow: View {
    let member: GroupMemberViewModel
    let isCurrentUser: Bool
    let isGroupAdmin: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProfileImageView(
                imageUrl: member.profilePicture,
                color: member.color,
                size: 40
            )
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(member.handle)")
                        .font(.pathway(16))

                    if isCurrentUser {
                        Text("(you)")
                            .font(.pathwayItalic(14))
                            .foregroundColor(.secondary)
                    }
                }

                if member.isAdmin {
                    Text("admin")
                        .font(.pathway(14))
                        .foregroundColor(.taskapeOrange)
                }
            }

            Spacer()

            if isGroupAdmin, !isCurrentUser {
                Button(action: onRemove) {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}
