import Alamofire
import SwiftData
import SwiftDotenv
import SwiftUI

struct GroupContentView: View {
    let group: taskapeGroup
    @Environment(\.modelContext) private var modelContext
    @State private var userTasks: [taskapeTask] = []
    @State private var otherMemberTasks: [taskapeTask] = []
    @State private var isLoading: Bool = false

    @State private var showAddTaskSheet = false
    @State private var showMembersSheet = false
    @State private var showInviteSheet = false
    @State private var updatingTaskIds: Set<String> = []

    @Namespace var namespace

    private var currentUserId: String {
        UserManager.shared.currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                NavigationLink(destination: {
                    GroupMembersView(group: group)
                        .modelContext(modelContext).toolbar(.hidden)
                        .navigationTransition(
                            .zoom(sourceID: "memberView", in: namespace))
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("members")
                    }
                    .font(.pathway(14))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .matchedTransitionSource(id: "memberView", in: namespace)
                    .background(Color(uiColor: UIColor.systemBackground))
                }.buttonStyle(PlainButtonStyle())
                    .cornerRadius(24)
                    .shadow(
                        color: Color.primary.opacity(0.08), radius: 8, x: 0,
                        y: 2
                    )

                Spacer()
                Button(action: { showInviteSheet = true }) {
                    Image(systemName: "plus").padding(.trailing)
                }.buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal).onAppear {}

            if isLoading {
                ProgressView("loading group tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userTasks.isEmpty, otherMemberTasks.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("no tasks yet")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)

                    Button(action: {
                        showAddTaskSheet = true
                    }) {
                        Text("add a task")
                            .font(.pathway(16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.taskapeOrange)
                            .cornerRadius(25)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !userTasks.isEmpty {
                            VStack(alignment: .leading) {
                                Text("tasks assigned to you")
                                    .font(.pathwayBold(18))
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                ForEach(userTasks) { task in
                                    TaskListItem(
                                        task: task,
                                        onToggleCompletion: {
                                            print(
                                                "Task toggle called for: \(task.id), new state: \(task.completion.isCompleted)"
                                            )
                                            updateTaskCompletion(task)
                                        }
                                    )
                                    .padding(.horizontal)
                                    .overlay(
                                        updatingTaskIds.contains(task.id)
                                            ? ProgressView()
                                            .frame(width: 24, height: 24)
                                            .padding()
                                            : nil,
                                        alignment: .trailing
                                    )
                                }
                            }
                        }

                        if !otherMemberTasks.isEmpty {
                            VStack(alignment: .leading) {
                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)

                                Text("other members' tasks")
                                    .font(.pathwayBold(18))
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                ForEach(otherMemberTasks) { task in
                                    TaskListItem(
                                        task: task,
                                        onToggleCompletion: {
                                            print(
                                                "Task toggle called for: \(task.id), new state: \(task.completion.isCompleted)"
                                            )
                                            updateTaskCompletion(task)
                                        }
                                    )
                                    .padding(.horizontal)
                                    .overlay(
                                        updatingTaskIds.contains(task.id)
                                            ? ProgressView()
                                            .frame(width: 24, height: 24)
                                            .padding()
                                            : nil,
                                        alignment: .trailing
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Button(action: {
                    showAddTaskSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.taskapeOrange)
                        .clipShape(Circle())
                        .shadow(
                            color: Color.black.opacity(0.2), radius: 4, x: 0,
                            y: 2
                        )
                }
                .padding(.bottom, 25).padding(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.top, 16)
        .onAppear {
            loadGroupTasks()
        }
        .sheet(isPresented: $showAddTaskSheet) {
            GroupTaskCreationView(
                group: group,
                onTaskCreated: { newTask in
                    if newTask.assignedToTask.contains(currentUserId) {
                        if newTask.assignedToTask.count == 1 {
                            userTasks.append(newTask)
                            return
                        }
                        userTasks.append(newTask)
                        otherMemberTasks.append(newTask)
                    } else {
                        otherMemberTasks.append(newTask)
                    }
                }
            )
            .modelContext(modelContext)
        }
        .sheet(isPresented: $showMembersSheet) {
            GroupMembersView(group: group)
                .modelContext(modelContext)
        }
        .sheet(isPresented: $showInviteSheet) {
            GroupInviteView(group: group)
                .modelContext(modelContext)
        }
    }

    private func loadGroupTasks() {
        isLoading = true

        Task { @MainActor in
            let tasks = await GroupManager.shared.loadGroupTasks(
                groupId: group.id,
                context: modelContext
            )

            await MainActor.run {
                userTasks = tasks.filter { task in
                    task.assignedToTask.contains(currentUserId)
                }

                otherMemberTasks = tasks.filter { task in
                    !(task.assignedToTask.contains(currentUserId))
                }

                isLoading = false
            }
        }
    }

    private func updateTaskCompletion(_ task: taskapeTask) {
        print(
            "Updating task completion for task: \(task.id), isCompleted: \(task.completion.isCompleted)"
        )

        updatingTaskIds.insert(task.id)

        Task {
            let success = await syncTaskChanges(task: task)

            await MainActor.run {
                updatingTaskIds.remove(task.id)

                if !success {
                    print("Task update failed, reverting: \(task.id)")
                    withAnimation {
                        task.completion.isCompleted.toggle()
                    }
                } else {
                    print("Task update succeeded: \(task.id)")

                    try? modelContext.save()

                    if let index = userTasks.firstIndex(where: {
                        $0.id == task.id
                    }) {
                        let updatedTask = task
                        userTasks[index] = updatedTask
                    } else if let index = otherMemberTasks.firstIndex(where: {
                        $0.id == task.id
                    }) {
                        let updatedTask = task
                        otherMemberTasks[index] = updatedTask
                    }
                }
            }
        }
    }

    private func syncTaskChanges(task: taskapeTask) async -> Bool {
        await updateTask(task: task)
    }
}

struct GroupTaskCreationView: View {
    let group: taskapeGroup
    var onTaskCreated: (taskapeTask) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var deadline: Date? = nil
    @State private var flagStatus: Bool = false
    @State private var flagColor: String? = nil
    @State private var flagName: String? = nil
    @State private var proofNeeded: Bool? = false
    @State private var confirmationRequired: Bool = false
    @State private var selectedMembers: [String] = []

    @State private var isLoading = false
    @State private var showMemberPicker = false
    @State private var groupMembers: [taskapeUser] = []
    @State private var taskColor: Color = .taskapeOrange
    @FocusState private var isFocused: Bool

    @State private var labels: [TaskFlag] = [
        TaskFlag(flagname: "important", flagcolor: "#FF6B6B"),
        TaskFlag(flagname: "work", flagcolor: "#FFD166"),
        TaskFlag(flagname: "study", flagcolor: "#06D6A0"),
        TaskFlag(flagname: "life", flagcolor: "#118AB2"),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TaskNameField(
                        name: $taskName,
                        flagColor: $flagColor,
                        flagName: $flagName
                    )

                    TaskDescriptionField(
                        description: $taskDescription,
                        isFocused: _isFocused,
                        accentcolor: $taskColor
                    )

                    TaskDeadlinePicker(
                        deadline: $deadline,
                        accentcolor: $taskColor
                    )

                    TaskPrioritySelector(
                        flagStatus: $flagStatus,
                        flagColor: $flagColor,
                        flagName: $flagName,
                        labels: $labels,
                        accentcolor: $taskColor
                    )

                    GroupMemberAssigneeSelector(
                        selectedMembers: $selectedMembers,
                        accentcolor: $taskColor,
                        group: group,
                        showMemberPicker: $showMemberPicker,
                        groupMembers: $groupMembers
                    )

                    ProofSelectRow(
                        task: makeTemporaryTask(),
                        proofNeeded: $proofNeeded,
                        accentcolor: $taskColor,
                        confirmationRequired: $confirmationRequired
                    )

                    Spacer(minLength: 40)

                    Button(action: createTask) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }

                            Text("add task")
                                .font(.pathwayBold(18))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(taskName.isEmpty ? Color.gray : taskColor)
                        )
                    }
                    .disabled(taskName.isEmpty || isLoading)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .toolbar(.hidden)
            .sheet(isPresented: $showMemberPicker) {
                GroupMemberPickerView(
                    members: groupMembers,
                    selectedMembers: $selectedMembers
                )
            }
        }
        .onChange(of: flagColor) { _, _ in
            taskColor = getTaskColor()
        }
        .onAppear {
            loadGroupMembers()
        }
    }

    private func loadGroupMembers() {
        Task {
            if let users = await getUsersBatch(userIds: group.members) {
                await MainActor.run {
                    groupMembers = users
                }
            }
        }
    }

    private func getTaskColor() -> Color {
        if flagColor != nil, flagName != nil {
            return Color(hex: flagColor!)
        }
        return Color.taskapeOrange.opacity(0.8)
    }

    private func makeTemporaryTask() -> taskapeTask {
        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: UserManager.shared.currentUserId,
            name: taskName,
            taskDescription: taskDescription,
            author: UserManager.shared.currentUserId,
            privacy: PrivacySettings(
                level: .group,
                groupID: group.id,
                exceptIDs: []
            )
        )

        task.proofNeeded = proofNeeded
        task.completion.requiresConfirmation = confirmationRequired

        return task
    }

    private func createTask() {
        guard !taskName.isEmpty else { return }

        isLoading = true

        let currentUserId = UserManager.shared.currentUserId

        let privacy = PrivacySettings(
            level: .group,
            groupID: group.id,
            exceptIDs: []
        )

        let newTask = taskapeTask(
            id: UUID().uuidString,
            user_id: currentUserId,
            name: taskName,
            taskDescription: taskDescription,
            author: currentUserId,
            privacy: privacy,
            group: group.name,
            group_id: group.id,
            assignedToTask: selectedMembers
        )
        print("SELECTED MEMBERRSSSSSS \(selectedMembers)")

        if let deadline {
            newTask.deadline = deadline
        }

        newTask.flagStatus = flagStatus
        newTask.flagColor = flagColor
        newTask.flagName = flagName
        newTask.proofNeeded = proofNeeded
        newTask.completion.requiresConfirmation = confirmationRequired

        modelContext.insert(newTask)

        Task {
            _ = await submitTasksBatch(tasks: [newTask])

            await MainActor.run {
                isLoading = false
                onTaskCreated(newTask)
                dismiss()
            }
        }
    }
}

struct GroupMemberAssigneeSelector: View {
    @Binding var selectedMembers: [String]
    @Binding var accentcolor: Color
    let group: taskapeGroup
    @Binding var showMemberPicker: Bool
    @Binding var groupMembers: [taskapeUser]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("assign to").font(.pathway(17))
                Spacer()

                Button(action: {
                    showMemberPicker = true
                }) {
                    HStack {
                        if selectedMembers.isEmpty {
                            Text("select members")
                                .font(.pathway(16))
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedMembers.count) members")
                                .font(.pathway(16))
                        }

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(accentcolor)
                            .padding(.trailing, 5)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding().padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)

            if !selectedMembers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedMembers, id: \.self) { memberId in
                            if let member = groupMembers.first(where: {
                                $0.id == memberId
                            }) {
                                SelectedMemberTag(
                                    member: member,
                                    onRemove: {
                                        selectedMembers.removeAll {
                                            $0 == memberId
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 40)
            }
        }
    }
}

struct SelectedMemberTag: View {
    let member: taskapeUser
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("@\(member.handle)")
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
                .fill(Color(hex: member.profileColor))
        )
    }
}

struct GroupMemberPickerView: View {
    let members: [taskapeUser]
    @Binding var selectedMembers: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredMembers: [taskapeUser] {
        if searchText.isEmpty {
            members
        } else {
            members.filter {
                $0.handle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)

                    TextField("search members", text: $searchText)
                        .font(.pathway(16))
                        .padding(10)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
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
                        .fill(Color(UIColor.systemGray6))
                        .stroke(.regularMaterial, lineWidth: 1)
                )
                .padding()

                if members.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("no group members")
                            .font(.pathway(18))
                            .foregroundColor(.secondary)

                        Text("invite members to your group to assign tasks")
                            .font(.pathwayItalic(15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else if filteredMembers.isEmpty {
                    VStack {
                        Spacer()
                        Text("no results found")
                            .font(.pathway(18))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            MemberSelectRow(
                                member: member,
                                isSelected: selectedMembers.contains(member.id),
                                onToggle: { selected in
                                    if selected {
                                        if !selectedMembers.contains(member.id) {
                                            selectedMembers.append(member.id)
                                        }
                                    } else {
                                        selectedMembers.removeAll {
                                            $0 == member.id
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitle("Select Members", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct MemberSelectRow: View {
    let member: taskapeUser
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                ProfileImageView(
                    imageUrl: member.profileImageURL,
                    color: member.profileColor,
                    size: 40
                )

                Text("@\(member.handle)")
                    .font(.pathwayBlack(16))
                    .padding(.leading, 10)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? Color.taskapeOrange : Color.gray.opacity(0.5),
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
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GroupMembersView: View {
    let group: taskapeGroup

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var members: [taskapeUser] = []
    @State private var memberTasks: [String: [taskapeTask]] = [:]
    @State private var isLoading = true
    @State private var selectedMember: taskapeUser? = nil

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading members...")
                        .font(.pathway(16))
                } else if members.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No members found")
                            .font(.pathway(18))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(members) { member in
                            Button(action: {
                                selectedMember = member
                            }) {
                                HStack {
                                    ProfileImageView(
                                        imageUrl: member.profileImageURL,
                                        color: member.profileColor,
                                        size: 40
                                    )

                                    VStack(alignment: .leading) {
                                        Text(member.handle)
                                            .font(.pathwayBold(16))

                                        let taskCount =
                                            (memberTasks[member.id] ?? [])
                                                .filter { $0.group_id == group.id }
                                                .count

                                        Text(
                                            "\(taskCount) group task\(taskCount == 1 ? "" : "s")"
                                        )
                                        .font(.pathway(14))
                                        .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("group members")
                        .font(.pathwayBold(16))
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                }.buttonStyle(PlainButtonStyle())
            )
            .sheet(item: $selectedMember) { member in
                MemberTasksView(
                    member: member,
                    tasks: memberTasks[member.id] ?? [],
                    group: group
                )
                .modelContext(modelContext)
            }
            .onAppear {
                loadGroupMembers()
            }
        }
    }

    private func loadGroupMembers() {
        isLoading = true

        Task {
            if let users = await getUsersBatch(userIds: group.members) {
                let tasksBatch = await BatchTaskManager.shared
                    .fetchTasksForUsers(
                        userIds: group.members
                    )

                await MainActor.run {
                    members = users

                    if let tasks = tasksBatch {
                        memberTasks = tasks
                    }

                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct MemberTasksView: View {
    let member: taskapeUser
    let tasks: [taskapeTask]
    let group: taskapeGroup

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var updatingTaskIds: Set<String> = []

    private var groupTasks: [taskapeTask] {
        tasks.filter { $0.group_id == group.id }
    }

    var body: some View {
        NavigationView {
            VStack {
                if groupTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("no group tasks assigned")
                            .font(.pathway(18))
                            .foregroundColor(.secondary)

                        Text("this member doesn't have any tasks in this group")
                            .font(.pathwayItalic(14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupTasks) { task in
                            TaskListItem(
                                task: task,
                                onToggleCompletion: {
                                    print(
                                        "Member task toggle called for: \(task.id), new state: \(task.completion.isCompleted)"
                                    )
                                    updateTaskCompletion(task)
                                }
                            )
                            .overlay(
                                updatingTaskIds.contains(task.id)
                                    ? ProgressView()
                                    .frame(width: 24, height: 24)
                                    .padding()
                                    : nil,
                                alignment: .trailing
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }.toolbar {
                ToolbarItem(placement: .principal) {
                    Text("@\(member.handle)'s group tasks").font(
                        .pathwayBold(18))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func updateTaskCompletion(_ task: taskapeTask) {
        updatingTaskIds.insert(task.id)

        Task {
            let success = await updateTask(task: task)

            await MainActor.run {
                updatingTaskIds.remove(task.id)

                if !success {
                    task.completion.isCompleted.toggle()
                }
            }
        }
    }
}
