

import CachedAsyncImage
import SwiftData
import SwiftUI

struct GroupView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var groupManager = GroupManager.shared

    @State private var isLoading = true
    @State private var tasks: [taskapeTask] = []
    @State private var showAddTaskSheet = false
    @State private var showInviteSheet = false
    @State private var showMembersSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if let selectedGroup = groupManager.selectedGroup {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedGroup.name)
                                .font(.pathwayBlack(24))
                                .foregroundColor(Color(hex: selectedGroup.color))

                            if !selectedGroup.group_description.isEmpty {
                                Text(selectedGroup.group_description)
                                    .font(.pathway(14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Menu {
                            Button(action: {
                                showAddTaskSheet = true
                            }) {
                                Label("Add Task", systemImage: "plus")
                            }

                            Button(action: {
                                showInviteSheet = true
                            }) {
                                Label("Invite Members", systemImage: "person.badge.plus")
                            }

                            Button(action: {
                                showMembersSheet = true
                            }) {
                                Label("View Members", systemImage: "person.3")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding([.horizontal, .top])

                    if isLoading {
                        ProgressView("Loading tasks...")
                            .padding(.top, 50)
                    } else if tasks.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .padding(.top, 50)

                            Text("no tasks in this group yet")
                                .font(.pathway(18))
                                .foregroundColor(.secondary)

                            Button(action: {
                                showAddTaskSheet = true
                            }) {
                                Text("create task")
                                    .font(.pathway(16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: selectedGroup.color))
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top, 20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(tasks) { task in
                                    TaskListItem(task: task)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 12)
                        }
                    }
                }
                .onAppear {
                    loadTasks()
                }
                .sheet(isPresented: $showAddTaskSheet) {
                    Text("Create Task View")
                }
                .sheet(isPresented: $showInviteSheet) {
                    InviteMembersView(group: selectedGroup)
                        .modelContext(modelContext)
                }
                .sheet(isPresented: $showMembersSheet) {
                    GroupMembersView(group: selectedGroup)
                        .modelContext(modelContext)
                }
            } else {
                Text("No group selected")
                    .font(.pathway(18))
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
    }

    private func loadTasks() {
        guard let group = groupManager.selectedGroup else { return }

        isLoading = true
        Task {
            let groupTasks = await groupManager.loadGroupTasks(groupId: group.id, context: modelContext)
            await MainActor.run {
                tasks = groupTasks
                isLoading = false
            }
        }
    }
}

struct InviteMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let group: taskapeGroup
    @ObservedObject private var groupManager = GroupManager.shared

    @State private var searchQuery = ""
    @State private var searchResults: [UserSearchResult] = []
    @State private var isSearching = false
    @State private var pendingInvites: Set<String> = []

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search users by @handle", text: $searchQuery)
                    .font(.pathway(16))
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: searchQuery) { _, newValue in
                        if newValue.count >= 3 {
                            performSearch()
                        } else if newValue.isEmpty {
                            searchResults = []
                        }
                    }

                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty, !searchQuery.isEmpty, searchQuery.count >= 3 {
                    Text("No users found matching '\(searchQuery)'")
                        .font(.pathway(16))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(searchResults, id: \.id) { user in
                            HStack {
                                ProfileImageView(
                                    imageUrl: user.profile_picture,
                                    color: user.color,
                                    size: 40
                                )

                                Text("@\(user.handle)")
                                    .font(.pathway(16))

                                Spacer()

                                if pendingInvites.contains(user.id) {
                                    Text("Invited")
                                        .font(.pathway(14))
                                        .foregroundColor(.green)
                                } else if group.members.contains(user.id) {
                                    Text("Member")
                                        .font(.pathway(14))
                                        .foregroundColor(.secondary)
                                } else {
                                    Button("Invite") {
                                        inviteUser(user)
                                    }
                                    .font(.pathway(14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: group.color))
                                    .cornerRadius(14)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Invite Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func performSearch() {
        isSearching = true

        Task {
            if let results = await searchUsers(query: searchQuery) {
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } else {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    private func inviteUser(_ user: UserSearchResult) {
        pendingInvites.insert(user.id)

        Task {
            let success = await groupManager.inviteUserToGroup(
                groupId: group.id,
                inviteeId: user.id
            )

            if !success {
                await MainActor.run {
                    pendingInvites.remove(user.id)
                }
            }
        }
    }
}
