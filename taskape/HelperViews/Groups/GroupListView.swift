

import SwiftData
import SwiftUI

struct GroupListView: View {
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var groupManager = GroupManager.shared
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if groupManager.groups.isEmpty {
                    EmptyGroupsView(
                        showingCreateGroup: $showingCreateGroup,
                        showingJoinGroup: $showingJoinGroup
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groupManager.groups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupCard(group: group)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("your groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingCreateGroup = true
                        }) {
                            Label("create new group", systemImage: "plus")
                                .font(.pathway(14))
                        }

                        Button(action: {
                            showingJoinGroup = true
                        }) {
                            Label("join group", systemImage: "person.badge.plus")
                                .font(.pathway(14))
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                GroupCreationView()
                    .modelContext(modelContext)
            }
            .sheet(isPresented: $showingJoinGroup) {
                GroupJoinView()
                    .modelContext(modelContext)
            }
            .onAppear {
                loadGroups()
            }
        }
    }

    private func loadGroups() {
        isLoading = true

        groupManager.loadUserGroups(context: modelContext)

        isLoading = false
    }
}

struct EmptyGroupsView: View {
    @Binding var showingCreateGroup: Bool
    @Binding var showingJoinGroup: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("no groups yet")
                .font(.pathway(20))
                .padding(.top, 10)

            Text("create or join a group to collaborate with friends")
                .font(.pathway(16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 15) {
                Button(action: {
                    showingCreateGroup = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("create new group")
                    }
                    .font(.pathway(18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.taskapeOrange)
                    .cornerRadius(30)
                }

                Button(action: {
                    showingJoinGroup = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("join existing group")
                    }
                    .font(.pathway(18))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(30)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

struct GroupCard: View {
    let group: taskapeGroup

    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color(hex: group.color))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(group.name.prefix(1)).uppercased())
                        .font(.pathwayBold(20))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(group.name)
                    .font(.pathwayBold(18))
                    .lineLimit(1)

                if !group.group_description.isEmpty {
                    Text(group.group_description)
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))

                    Text("\(group.members.count) members")
                        .font(.pathway(12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(group.tasks.count) tasks")
                        .font(.pathway(12))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: taskapeGroup.self, inMemory: true)
}
