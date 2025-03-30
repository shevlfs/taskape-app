import SwiftData
import SwiftUI

// COMPONENT 1: Header with close button
struct DetailViewHeader: View {
    @Binding var detailIsPresent: Bool

    var body: some View {
        Button(action: {
            detailIsPresent.toggle()
        }) {
            Image(systemName: "chevron.down")
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// COMPONENT 2: Task name input field
struct TaskNameField: View {
    @Binding var name: String
    @Environment(\.colorScheme) var colorScheme
    @Binding var flagColor: String?
    @Binding var flagName: String?

    private func getTaskColor()
        -> Color
    {
        if flagColor != nil && flagName != "" {
            return Color(hex: flagColor!)
        }
        return Color.taskapeOrange.opacity(0.8)
    }

    private func getTaskTextColor()
        -> Color
    {
        if flagColor != nil && flagName != "" {
            return Color(hex: flagColor!).contrastingTextColor(in: colorScheme)
        }
        return Color.white
    }

    var body: some View {
        HStack {
            TextField(
                "what needs to be done?", text: $name
            )
            .padding(15)
            .accentColor(
                getTaskTextColor()
            )
            .foregroundStyle(
                getTaskTextColor()
            )
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .font(.pathwayBlack(18))

            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    getTaskColor()
                )
                .stroke(.regularMaterial, lineWidth: 1)
                .blur(radius: 0.5)
        )
        .padding()
    }
}

// COMPONENT 3: Task description field
struct TaskDescriptionField: View {
    @Binding var description: String
    @FocusState var isFocused: Bool

    @Binding var accentcolor: Color

    var body: some View {
        TextEditor(text: $description)
            .font(.pathway(17))
            .focused($isFocused)
            .foregroundColor(Color.primary)
            .padding()
            .scrollContentBackground(.hidden)
            .accentColor(accentcolor)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .frame(minHeight: 100, maxHeight: 170)
            .padding(.horizontal)
    }
}

// COMPONENT 4: Deadline date picker
struct TaskDeadlinePicker: View {
    @Binding var deadline: Date?
    @Binding var accentcolor: Color

    var body: some View {
        DatePicker(
            "due date",
            selection: Binding(
                get: { deadline ?? Date() },
                set: { deadline = $0 }
            ),
            displayedComponents: [.date, .hourAndMinute]
        )
        .font(.pathway(17))
        .padding()
        .accentColor(accentcolor)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// COMPONENT 5: Priority selector
struct TaskPrioritySelector: View {
    @Binding var flagStatus: Bool
    @Binding var flagColor: String?
    @Binding var flagName: String?
    @Binding var labels: [TaskFlag]
    @State private var showPriorityPicker: Bool = false
    @Binding var accentcolor: Color

    // Predefined flag options
    @State var priorityOptions: [TaskFlag] = [
        TaskFlag(flagname: "important", flagcolor: "#FF6B6B"),
        TaskFlag(flagname: "work", flagcolor: "#FFD166"),
        TaskFlag(flagname: "study", flagcolor: "#06D6A0"),
        TaskFlag(flagname: "life", flagcolor: "#118AB2"),
    ]

    var body: some View {
        HStack {
            Text("label").font(.pathway(17))
            Spacer()

            Button(action: {
                showPriorityPicker.toggle()
            }) {
                HStack {
                    if flagStatus, let colorHex = flagColor {
                        let priorityLabel =
                            priorityOptions.first { $0.flagColor == colorHex }?
                            .flagName ?? flagName ?? "Custom"
                        Group {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 12, height: 12)
                            Text(priorityLabel)
                                .font(.pathway(17))
                        }.padding(.vertical, 5)
                    } else {
                        Group {
                            Text("none")
                                .font(.pathway(17))
                                .foregroundColor(.secondary)
                        }.padding(.vertical, 5)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(accentcolor).padding(
                            .trailing, 12)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showPriorityPicker) {
                PriorityPickerContent(
                    flagStatus: $flagStatus,
                    flagColor: $flagColor,
                    flagName: $flagName,
                    priorityOptions: getLabels(),
                    showPicker: $showPriorityPicker
                ).presentationDetents([.medium])
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    private func getLabels() -> [TaskFlag] {
        return (priorityOptions + uniqueFlags).uniqued()
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

// COMPONENT 5.1: Priority picker content
struct PriorityPickerContent: View {
    @Binding var flagStatus: Bool
    @Binding var flagColor: String?
    @Binding var flagName: String?
    @State var priorityOptions: [TaskFlag]
    @Binding var showPicker: Bool

    @State private var isAddingCustomLabel: Bool = false
    @State private var customColor: Color = .orange
    @State private var customLabelName: String = ""

    private let defaultColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan,
        .teal, .indigo,
    ]

    var body: some View {
        if isAddingCustomLabel {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: {
                        isAddingCustomLabel = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.taskapeOrange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 15)
                    Spacer()

                    Text("new label")
                        .font(.pathway(17))
                        .fontWeight(.medium)
                        .offset(x: -10)

                    Spacer()
                }.padding(.vertical)

                Divider()

                Spacer()

                // Label name field
                Text("label name")
                    .font(.pathway(17))
                    .padding(.horizontal)

                TextField("enter label name", text: $customLabelName)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.pathway(17))
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(30).background(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.regularMaterial, lineWidth: 1)
                    )
                    .padding(.horizontal).padding(.top).padding(.bottom, 25)

                Text("label color")
                    .font(.pathway(17))
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ColorPicker("", selection: $customColor)
                            .labelsHidden()
                            .frame(width: 30, height: 30)
                        ForEach(defaultColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            customColor == color
                                                ? Color.gray : Color.clear,
                                            lineWidth: 2)
                                )
                                .onTapGesture {
                                    customColor = color
                                }
                        }
                    }
                    .padding(8)
                }
                .padding(.top).padding(.horizontal).padding(.bottom, 20)

                Spacer()
                Button(action: {
                    withAnimation {
                        flagStatus = true
                        flagColor = customColor.toHex()
                        flagName =
                            customLabelName.isEmpty ? "Custom" : customLabelName
                        showPicker = false
                        FlagManager.shared.flagChanged()
                    }
                }) {
                    Text("add label")
                        .font(.pathway(17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    customLabelName.isEmpty
                                        ? Color.gray : Color.taskapeOrange)
                        )
                }.padding(.bottom, 10)
                    .buttonStyle(PlainButtonStyle())
                    .disabled(customLabelName.isEmpty)
                    .padding(.horizontal)
            }
        } else {
            // LABEL SELECTION VIEW
            VStack(spacing: 0) {
                // Header
                Text("select label")
                    .font(.pathway(17))
                    .fontWeight(.medium)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider()
                    .padding(.bottom, 8)

                // Standard label options
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(priorityOptions, id: \.flagName) { option in
                            Button(action: {
                                withAnimation {
                                    flagStatus = true
                                    flagColor = option.flagColor
                                    flagName = option.flagName
                                    showPicker = false
                                    FlagManager.shared.flagChanged()
                                }
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: option.flagColor))
                                        .frame(width: 18, height: 18)

                                    Text(option.flagName)
                                        .font(.pathway(17))
                                        .padding(.leading, 12)

                                    Spacer()

                                    if flagStatus
                                        && flagColor == option.flagColor
                                        && flagName == option.flagName
                                    {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 14)
                                .padding(.horizontal, 25)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button(action: {
                            withAnimation {
                                flagStatus = false
                                flagColor = nil
                                flagName = nil
                                showPicker = false
                                FlagManager.shared.flagChanged()
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(.gray))
                                    .frame(width: 18, height: 18)

                                Text("none")
                                    .font(.pathway(17))
                                    .padding(.leading, 12)

                                Spacer()

                                if !flagStatus && flagColor == nil
                                    && flagName == nil
                                {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 14)
                            .padding(.horizontal, 25)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .padding(.vertical, 8)

                        // Add custom label button
                        Button(action: {
                            withAnimation {
                                isAddingCustomLabel = true
                                customLabelName = ""
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.taskapeOrange)
                                    .font(.system(size: 18)).frame(
                                        width: 18, height: 18)

                                Text("add custom label")
                                    .font(.pathway(17))
                                    .foregroundColor(.taskapeOrange)
                                    .padding(.leading, 12)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 14)
                            .padding(.horizontal, 25)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// COMPONENT 6: Privacy selector
struct TaskPrivacySelector: View {
    @Binding var privacyLevel: PrivacySettings.PrivacyLevel
    @Binding var accentcolor: Color

    var body: some View {
        HStack {
            Text("privacy").font(.pathway(17))
            Spacer()

            Picker("privacy", selection: $privacyLevel) {
                Text("everyone").tag(PrivacySettings.PrivacyLevel.everyone)
                Text("no one").tag(PrivacySettings.PrivacyLevel.noone)
                Text("friends only").tag(
                    PrivacySettings.PrivacyLevel.friendsOnly)
                Text("everyone except").tag(
                    PrivacySettings.PrivacyLevel.except)
            }.font(.pathwayBold(17))
                .pickerStyle(MenuPickerStyle())
                .accentColor(accentcolor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// COMPONENT 7: Except People Selector
struct ExceptPeopleSelector: View {
    @Bindable var task: taskapeTask
    @ObservedObject private var friendManager = FriendManager.shared
    @State private var isLoading: Bool = false
    @State private var showingFriendsList: Bool = false
    @Binding var accentcolor: Color

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                // Load friends data if needed and show selection list
                if friendManager.friends.isEmpty {
                    isLoading = true
                    Task {
                        await friendManager.refreshFriendData()
                        await MainActor.run {
                            isLoading = false
                            showingFriendsList = true
                        }
                    }
                } else {
                    showingFriendsList = true
                }
            }) {
                HStack {
                    Text("select people to exclude")
                        .font(.pathway(17))
                        .foregroundColor(accentcolor)

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Text("\(task.privacy.exceptIDs.count) selected")
                            .font(.pathwayItalic(14))
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(accentcolor)
                    }
                }
                .padding(.horizontal).padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(accentcolor.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 30).fill(
                                Color(UIColor.secondarySystemBackground)))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)

            // Friend tags display when friends are excluded
            if !task.privacy.exceptIDs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(task.privacy.exceptIDs, id: \.self) {
                            friendId in
                            ExcludedFriendTag(
                                friendId: friendId,
                                task: task
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .frame(height: 40)
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingFriendsList) {
            FriendSelectionSheet(task: task, accentcolor: $accentcolor)
                .presentationDetents([.medium])
        }
    }
}

// Excluded friend tag component
struct ExcludedFriendTag: View {
    let friendId: String
    @Bindable var task: taskapeTask
    @ObservedObject private var friendManager = FriendManager.shared

    private var friendName: String {
        friendManager.friends.first(where: { $0.id == friendId })?.handle
            ?? "unknown"
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("@\(friendName)")
                .font(.pathway(14))
                .foregroundColor(.white)

            Button(action: {
                withAnimation {
                    // Remove this friend from the excluded list
                    task.privacy.exceptIDs.removeAll(where: { $0 == friendId })
                }
            }) {
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

// Friend selection sheet
struct FriendSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: taskapeTask
    @ObservedObject private var friendManager = FriendManager.shared
    @State private var searchText: String = ""

    @Binding var accentcolor: Color

    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friendManager.friends
        } else {
            return friendManager.friends.filter {
                $0.handle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("exclude friends")
                    .font(.pathwayBold(18))

                Spacer()

                Button("done") {
                    dismiss()
                }
                .font(.pathway(16))
                .foregroundColor(accentcolor)
            }
            .padding()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 10)

                TextField("search friends", text: $searchText)
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
                    .fill(Color(UIColor.systemGray6)).stroke(
                        .regularMaterial, lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 10)

            if friendManager.friends.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Text("no friends yet")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)

                    Text("add friends to exclude them from seeing this task")
                        .font(.pathwayItalic(15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else if filteredFriends.isEmpty {
                VStack {
                    Spacer()
                    Text("no results found")
                        .font(.pathway(18))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // Friends list
                List {
                    ForEach(filteredFriends, id: \.id) { friend in
                        FriendSelectRow(
                            friend: friend,
                            isSelected: task.privacy.exceptIDs.contains(
                                friend.id),
                            onToggle: { selected in
                                if selected {
                                    // Add to excluded IDs
                                    if !task.privacy.exceptIDs.contains(
                                        friend.id)
                                    {
                                        task.privacy.exceptIDs.append(friend.id)
                                    }
                                } else {
                                    // Remove from excluded IDs
                                    task.privacy.exceptIDs.removeAll(where: {
                                        $0 == friend.id
                                    })
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            // Refresh friend data when the sheet appears
            if friendManager.friends.isEmpty {
                Task {
                    await friendManager.refreshFriendData()
                }
            }
        }
    }
}

// Friend selection row component
struct FriendSelectRow: View {
    let friend: Friend
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                // Profile image or placeholder
                if !friend.profile_picture.isEmpty {
                    AsyncImage(url: URL(string: friend.profile_picture)) {
                        phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        case .failure, .empty:
                            Circle()
                                .fill(Color(hex: friend.color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(
                                        String(friend.handle.prefix(1))
                                            .uppercased()
                                    )
                                    .font(.pathwayBold(16))
                                    .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color(hex: friend.color))
                                .frame(width: 40, height: 40)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color(hex: friend.color))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(friend.handle.prefix(1)).uppercased())
                                .font(.pathwayBold(16))
                                .foregroundColor(.white)
                        )
                }

                Text("@\(friend.handle)")
                    .font(.pathwayBlack(16))
                    .padding(.leading, 10)

                Spacer()

                // Checkmark or empty circle
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

struct ProofSelectRow: View {
    @Binding var proofNeeded: Bool?
    @Binding var accentcolor: Color

    var body: some View {
        HStack {
            Text("proof needed").font(.pathway(17))
            Spacer()

            Picker("", selection: $proofNeeded) {
                Text("yes").tag(true)
                Text("no").tag(false)
            }.font(.pathwayBold(17))
                .pickerStyle(MenuPickerStyle())
                .accentColor(accentcolor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// MAIN VIEW: Refactored into components
struct taskCardDetailView: View {
    @Binding var detailIsPresent: Bool
    @Bindable var task: taskapeTask
    @State var labels: [TaskFlag] = []
    @FocusState var isFocused: Bool
    @State var taskColor: Color = .taskapeOrange
    @State var detents: Set<PresentationDetent> = [.large]

    var body: some View {
        Group {
            VStack {
                // Component 1: Header
                //DetailViewHeader(detailIsPresent: $detailIsPresent)

                // Component 2: Task name field
                TaskNameField(
                    name: $task.name, flagColor: $task.flagColor,
                    flagName: $task.flagName)

                // Component 3: Task description field
                TaskDescriptionField(
                    description: $task.taskDescription, isFocused: _isFocused, accentcolor: $taskColor)

                // Component 4: Deadline picker
                TaskDeadlinePicker(deadline: $task.deadline, accentcolor: $taskColor)

                // Component 5: Priority selector
                TaskPrioritySelector(
                    flagStatus: $task.flagStatus,
                    flagColor: $task.flagColor,
                    flagName: $task.flagName, labels: $labels, accentcolor: $taskColor
                )

                // Component 6: Privacy selector
                TaskPrivacySelector(
                    privacyLevel: $task.privacy.level,
                    accentcolor: $taskColor
                )

                // Conditional content based on privacy level
                switch task.privacy.level {
                case .everyone, .noone, .friendsOnly:
                    EmptyView()
                case .group:
                    Text("group selection")
                case .except:
                    EmptyView()
                }

                if task.privacy.level == .except {
                    ExceptPeopleSelector(task: task, accentcolor: $taskColor)
                        .transition(
                            .move(edge: .bottom).combined(with: .opacity))
                }
                ProofSelectRow(
                    proofNeeded: $task.proofNeeded,
                    accentcolor: $taskColor
                )

            }.animation(.easeInOut(duration: 0.3), value: task.privacy.level)
                .padding(.top, 20)

            Spacer()
        }
        .presentationDetents(detents)
        .animation(.easeInOut, value: detents)
        .onAppear {
            self.taskColor = self.getTaskColor()
        }
        .onChange(of: task.flagColor) { _, _ in
            self.taskColor = self.getTaskColor()
        }
    }

    private func getTaskColor() -> Color {
        if task.flagColor != nil && task.flagName != "" {
            return Color(hex: task.flagColor!)
        }
        return Color.taskapeOrange.opacity(0.8)
    }
}

// Preview


//#Preview {
//    @State var task = taskapeTask(
//        name: "Complete project",
//        taskDescription: "Finish all the views and connect them",
//        author: "shevlfs",
//        privacy: "private",
//        flagStatus: true,
//        flagColor: "#FF6B6B",
//        flagName: "High"
//    )
//
//    return taskCardDetailView(detailIsPresent: .constant(true), task: task, taskColor: .constant("#FF6B6B"))
//}
