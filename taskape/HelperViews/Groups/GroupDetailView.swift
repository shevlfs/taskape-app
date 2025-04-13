import SwiftData
import SwiftUI

struct GroupDetailView: View {
    @Bindable var group: taskapeGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject private var groupManager = GroupManager.shared

    @State private var isLoadingTasks = false
    @State private var showingInviteSheet = false
    @State private var showingMembersSheet = false
    @State private var showingCreateTaskSheet = false

    private var isGroupAdmin: Bool {
        group.isAdmin(userId: UserManager.shared.currentUserId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .fill(Color(hex: group.color))
                        .frame(height: 150)

                    VStack(spacing: 10) {
                        Text(group.name)
                            .font(.pathwayBlack(24))
                            .foregroundColor(
                                Color(hex: group.color).contrastingTextColor(
                                    in: colorScheme))

                        Text("\(group.members.count) members")
                            .font(.pathway(14))
                            .foregroundColor(
                                Color(hex: group.color).contrastingTextColor(
                                    in: colorScheme
                                ).opacity(0.7))

                        if !group.group_description.isEmpty {
                            Text(group.group_description)
                                .font(.pathway(16))
                                .foregroundColor(
                                    Color(hex: group.color)
                                        .contrastingTextColor(in: colorScheme)
                                )
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                }

                HStack(spacing: 15) {
                    ActionButton(
                        title: "invite",
                        icon: "person.badge.plus",
                        action: { showingInviteSheet = true }
                    )

                    ActionButton(
                        title: "members",
                        icon: "person.2",
                        action: { showingMembersSheet = true }
                    )

                    ActionButton(
                        title: "new task",
                        icon: "plus.circle",
                        action: { showingCreateTaskSheet = true }
                    )
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(Color(UIColor.secondarySystemBackground))

                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("group tasks")
                            .font(.pathwayBold(20))

                        Spacer()

                        if isLoadingTasks {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)

                    if group.tasks.isEmpty {
                        EmptyTasksView()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(group.tasks) { task in
                                GroupTaskItem(task: task)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(group.name)
                    .font(.pathwayBold(16))
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            GroupInviteView(group: group)
                .modelContext(modelContext)
        }
        .sheet(isPresented: $showingMembersSheet) {
            GroupMembersView(group: group)
                .modelContext(modelContext)
        }
        .sheet(isPresented: $showingCreateTaskSheet) {
            GroupTaskCreationView(group: group, onTaskCreated: { _ in })
                .modelContext(modelContext)
        }
        .onAppear {
            refreshGroupTasks()
        }
    }

    private func refreshGroupTasks() {
        isLoadingTasks = true

        Task {
            _ = await groupManager.loadGroupTasks(
                groupId: group.id, context: modelContext
            )

            await MainActor.run {
                isLoadingTasks = false
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.taskapeOrange)

                Text(title)
                    .font(.pathway(14))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
        }
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 15) {
            Spacer()

            Image(systemName: "list.clipboard")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("no tasks yet")
                .font(.pathway(18))

            Text("create a task to start collaborating")
                .font(.pathway(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()
        }
        .frame(height: 200)
        .padding()
    }
}

struct GroupTaskItem: View {
    @Bindable var task: taskapeTask
    @State private var showingTaskDetail = false

    var body: some View {
        Button(action: {
            showingTaskDetail = true
        }) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(
                            task.completion.isCompleted
                                ? Color.green : Color.gray.opacity(0.6),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if task.completion.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.pathway(16))
                        .foregroundColor(.primary)
                        .strikethrough(task.completion.isCompleted)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if !task.assignedToTask.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .font(.system(size: 10))

                                Text("\(task.assignedToTask.count) assigned")
                                    .font(.pathway(12))
                            }
                            .foregroundColor(.secondary)
                        }

                        if let deadline = task.deadline {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))

                                Text(formatDate(deadline))
                                    .font(.pathway(12))
                            }
                            .foregroundColor(
                                isPastDue(deadline) ? .red : .secondary)
                        }

                        if task.flagStatus, let flagColor = task.flagColor {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: flagColor))
                                    .frame(width: 8, height: 8)

                                Text(task.flagName ?? "")
                                    .font(.pathway(12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .contentShape(Rectangle())
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTaskDetail) {
            TaskDetailView(task: task)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func isPastDue(_ date: Date) -> Bool {
        date < Date()
    }
}

struct TaskDetailView: View {
    @Bindable var task: taskapeTask

    var body: some View {
        Text("Task Detail: \(task.name)")
            .font(.pathway(16))
            .padding()
    }
}

#Preview {
    let group = createPreviewGroup()

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: taskapeGroup.self, taskapeTask.self, configurations: config
    )

    NavigationStack {
        GroupDetailView(group: group)
            .modelContainer(container)
    }
}

func createPreviewGroup() -> taskapeGroup {
    let group = taskapeGroup(
        id: UUID().uuidString,
        name: "design team",
        group_description: "collaborate on design projects and discuss ideas",
        color: "#FF6B6B",
        creatorId: "user123"
    )

    let task1 = taskapeTask(
        id: UUID().uuidString,
        user_id: "user123",
        name: "design the new logo",
        taskDescription: "create a modern logo that represents our brand values",
        author: "user123",
        privacy: PrivacySettings(level: .everyone)
    )

    let task2 = taskapeTask(
        id: UUID().uuidString,
        user_id: "user123",
        name: "finalize color palette",
        taskDescription: "select the final colors for our brand",
        author: "user123",
        privacy: PrivacySettings(level: .everyone)
    )
    task2.completion.isCompleted = true

    group.tasks.append(task1)
    group.tasks.append(task2)

    UserManager.shared.currentUserId = "user123"

    return group
}
