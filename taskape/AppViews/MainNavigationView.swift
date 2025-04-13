import CachedAsyncImage
import SwiftData
import SwiftUI

struct MainNavigationView: View {
    @State private var selectedTabIndex: Int = 1
    @State var mainTabBarItems: [tabBarItem] = [
        tabBarItem(title: "settings"),
        tabBarItem(title: "main"),
    ]

    @State var eventsUpdated: Bool = false

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    @State private var currentUser: taskapeUser?
    @Query var tasks: [taskapeTask]

    @State private var mainNavigationPath = NavigationPath()

    @State private var isLoading: Bool = true
    @State private var logoOpacity: Double = 1.0
    @State private var contentOpacity: Double = 0.0
    @State private var contentScale: CGFloat = 0.8

    @Namespace private var main

    @Binding var fullyLoaded: Bool

    @State var showGroupSheet: Bool = false

    @ObservedObject private var groupManager = GroupManager.shared

    var body: some View {
        NavigationStack(path: $mainNavigationPath) {
            VStack {
                UserGreetingCard(
                    user: $currentUser
                ).modelContext(modelContext).padding(.horizontal).padding(
                    .top, 10
                ).padding(.bottom, 10)

                MainMenuTabBarView(
                    tabBarItems: $mainTabBarItems,
                    tabBarViewIndex: $selectedTabIndex,
                    showGroupSheet: $showGroupSheet
                ).ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .toolbar(.hidden)

                if groupManager.selectedGroup != nil {
                    GroupContentView(
                        group: groupManager.selectedGroup!
                    )
                    .modelContext(modelContext)
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: .infinity)
                    .toolbar(.hidden)
                    .gesture(createHorizontalSwipeGesture())
                } else {
                    switch selectedTabIndex {
                    case 0:
                        SettingsView()
                            .modelContext(modelContext)
                            .environmentObject(appState)
                            .gesture(createHorizontalSwipeGesture())
                    case 1:
                        MainView(
                            eventsUpdated: $eventsUpdated,
                            navigationPath: $mainNavigationPath
                        )
                        .modelContext(modelContext)
                        .ignoresSafeArea(.all)
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxHeight: .infinity)
                        .toolbar(.hidden)
                        .gesture(createHorizontalSwipeGesture())
                    default:
                        Text("Unknown view")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(UIColor.systemBackground))
                    }
                }

                Spacer()
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden)
            .sheet(isPresented: $showGroupSheet, content: {
                GroupCreationView().modelContext(modelContext)
            })
        }
        .onAppear {
            print($mainNavigationPath)
            currentUser = UserManager.shared.getCurrentUser(context: modelContext)

            groupManager.loadUserGroups(context: modelContext)
        }
    }

    private func createHorizontalSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height

                if abs(horizontalAmount) > abs(verticalAmount) {
                    handleHorizontalSwipe(horizontalAmount: horizontalAmount)
                }
            }
    }

    private func handleHorizontalSwipe(horizontalAmount: CGFloat) {
        withAnimation {
            if groupManager.selectedGroup != nil {
                if horizontalAmount > 0 {
                    selectedTabIndex = 1
                    groupManager.selectedGroup = nil
                }
            } else {
                if horizontalAmount < 0 {
                    selectedTabIndex = min(
                        selectedTabIndex + 1,
                        mainTabBarItems.count - 1
                    )
                } else {
                    selectedTabIndex = max(
                        0, selectedTabIndex - 1
                    )
                }
            }
        }
    }
}

struct GroupContentView: View {
    let group: taskapeGroup
    @Environment(\.modelContext) private var modelContext
    @State private var groupTasks: [taskapeTask] = []
    @State private var isLoading: Bool = false

    @State private var showAddTaskSheet = false
    @State private var showMembersSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: {
                    showMembersSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Members")
                    }
                    .font(.pathway(14))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(hex: group.color))
                    .cornerRadius(20)
                }

                Spacer()

                Button(action: {
                    loadGroupTasks()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)

            if isLoading {
                ProgressView("Loading group tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if groupTasks.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No tasks yet")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)

                    Button(action: {
                        showAddTaskSheet = true
                    }) {
                        Text("Add a task")
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
                        ForEach(groupTasks) { task in
                            TaskListItem(task: task)
                                .padding(.horizontal)
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
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .center)
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
                    groupTasks.append(newTask)
                    loadGroupTasks()
                }
            )
        }

        .sheet(isPresented: $showMembersSheet) {
            GroupMembersView(group: group)
        }
    }

    private func loadGroupTasks() {
        isLoading = true

        Task {
            let tasks = await GroupManager.shared.loadGroupTasks(
                groupId: group.id,
                context: modelContext
            )

            await MainActor.run {
                groupTasks = tasks
                isLoading = false
            }
        }
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
                            if let member = groupMembers.first(where: { $0.id == memberId }) {
                                SelectedMemberTag(
                                    member: member,
                                    onRemove: {
                                        selectedMembers.removeAll { $0 == memberId }
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
                                        selectedMembers.removeAll { $0 == member.id }
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

                                        let taskCount = memberTasks[member.id]?.count ?? 0
                                        Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
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
                }
            }.toolbar {
                ToolbarItem(placement: .principal) {
                    Text("group members")
                        .font(.pathway(16))
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }.buttonStyle(PlainButtonStyle())
            )
            .sheet(item: $selectedMember) { member in
                MemberTasksView(
                    member: member,
                    tasks: memberTasks[member.id] ?? []
                )
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
                let tasksBatch = await BatchTaskManager.shared.fetchTasksForUsers(
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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No tasks assigned")
                            .font(.pathway(18))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(tasks) { task in
                            TaskListItem(task: task)
                        }
                    }
                }
            }
            .navigationBarTitle("@\(member.handle)'s Tasks", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Back") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeUser.self, taskapeTask.self, taskapeGroup.self,
            configurations: config
        )

        let user = taskapeUser(
            id: UUID().uuidString,
            handle: "shevlfs",
            bio: "i am shevlfs",
            profileImage:
            "https://static.wikia.nocookie.net/character-stats-and-profiles/images/c/c7/DZuvg1d.png/revision/latest?cb=20181120135131",
            profileColor: "blue"
        )

        container.mainContext.insert(user)

        let task = taskapeTask(
            id: UUID().uuidString,
            user_id: user.id,
            name: "Sample Task",
            taskDescription: "This is a sample task description",
            author: "shevlfs",
            privacy: "private"
        )

        container.mainContext.insert(task)
        user.tasks.append(task)

        let group = taskapeGroup(
            id: UUID().uuidString,
            name: "Sample Group",
            group_description: "This is a sample group for testing",
            color: "#4CD97B",
            creatorId: user.id
        )

        container.mainContext.insert(group)

        try container.mainContext.save()

        return MainNavigationView(fullyLoaded: .constant(true))
            .modelContainer(container)
            .environmentObject(AppStateManager())
    } catch {
        return Text("failed to create preview: \(error.localizedDescription)")
    }
}
