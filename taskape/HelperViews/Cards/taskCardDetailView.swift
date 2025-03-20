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

    var body: some View {
        HStack {
            TextField(
                "what needs to be done?", text: $name
            )
            .padding(15)
            .accentColor(Color.taskapeOrange)
            .foregroundStyle(Color.white)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .font(.pathwayBlack(18))

            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.taskapeOrange.opacity(0.8))
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

    var body: some View {
        TextEditor(text: $description)
            .font(.pathway(17))
            .focused($isFocused)
            .foregroundColor(Color.primary)
            .padding()
            .scrollContentBackground(.hidden)
            .accentColor(Color.taskapeOrange)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .frame(maxHeight: 150)
            .padding(.horizontal)
    }
}

// COMPONENT 4: Deadline date picker
struct TaskDeadlinePicker: View {
    @Binding var deadline: Date?

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
        .accentColor(Color.taskapeOrange)
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
    @State private var showPriorityPicker: Bool = false

    // Predefined flag options
    private let priorityOptions = [
        (label: "High", color: "#FF6B6B"),
        (label: "Medium", color: "#FFD166"),
        (label: "Low", color: "#06D6A0"),
        (label: "Info", color: "#118AB2"),
        (label: "Planning", color: "#073B4C")
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
                        let priorityLabel = priorityOptions.first { $0.color == colorHex }?.label ?? "Custom"
                        Group{
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 12, height: 12)
                            Text(priorityLabel)
                                .font(.pathway(17))
                        }.padding(.vertical, 5)
                    } else {
                        Group{
                            Text("None")
                                .font(.pathway(17))
                            .foregroundColor(.secondary)}.padding(.vertical, 5)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Color.taskapeOrange).padding(.trailing,12)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showPriorityPicker) {
                PriorityPickerContent(
                    flagStatus: $flagStatus,
                    flagColor: $flagColor,
                    flagName: $flagName,
                    priorityOptions: priorityOptions,
                    showPicker: $showPriorityPicker
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// COMPONENT 5.1: Priority picker content
struct PriorityPickerContent: View {
    @Binding var flagStatus: Bool
    @Binding var flagColor: String?
    @Binding var flagName: String?
    let priorityOptions: [(label: String, color: String)]
    @Binding var showPicker: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("set label")
                .font(.pathwayBold(16))
                .padding(.top)

            Divider()

            ForEach(priorityOptions, id: \.color) { option in
                Button(action: {
                    withAnimation {
                        flagStatus = true
                        flagColor = option.color
                        flagName = option.label
                        showPicker = false

                        FlagManager.shared.flagChanged()
                    }
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: option.color))
                            .frame(width: 16, height: 16)
                        Text(option.label)
                            .font(.pathway(15))
                        Spacer()
                        if flagStatus && flagColor == option.color {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider()

            Button(action: {
                withAnimation {
                    flagStatus = false
                    flagColor = nil
                    flagName = nil
                    showPicker = false

                    // Notify that flags have changed
                    FlagManager.shared.flagChanged()
                }
            }) {
                HStack {
                    Text("None")
                        .font(.pathway(15))
                    Spacer()
                    if !flagStatus {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical)
    }
}

// COMPONENT 6: Privacy selector
struct TaskPrivacySelector: View {
    @Binding var privacyLevel: PrivacySettings.PrivacyLevel

    var body: some View {
        HStack {
            Text("privacy").font(.pathway(17))
            Spacer()

            Picker("privacy", selection: $privacyLevel) {
                Text("everyone").tag(PrivacySettings.PrivacyLevel.everyone)
                Text("no one").tag(PrivacySettings.PrivacyLevel.noone)
                Text("friends only").tag(PrivacySettings.PrivacyLevel.friendsOnly)
                Text("group").tag(PrivacySettings.PrivacyLevel.group)
                Text("everyone except...").tag(PrivacySettings.PrivacyLevel.except)
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(Color.taskapeOrange)
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

    @FocusState var isFocused: Bool

    var body: some View {
        Group {
            VStack {
                // Component 1: Header
                DetailViewHeader(detailIsPresent: $detailIsPresent)

                // Component 2: Task name field
                TaskNameField(name: $task.name)

                // Component 3: Task description field
                TaskDescriptionField(description: $task.taskDescription, isFocused: _isFocused)

                // Component 4: Deadline picker
                TaskDeadlinePicker(deadline: $task.deadline)

                // Component 5: Priority selector
                TaskPrioritySelector(
                    flagStatus: $task.flagStatus,
                    flagColor: $task.flagColor,
                    flagName: $task.flagName
                )

                // Component 6: Privacy selector
                TaskPrivacySelector(privacyLevel: $task.privacy.level)

                // Conditional content based on privacy level
                switch task.privacy.level {
                case .everyone, .noone, .friendsOnly:
                    EmptyView()
                case .group:
                    Text("group selection")
                case .except:
                    Text("except people selection")
                }
            }
            .padding(.top, 20)

            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
}

// Preview
#Preview {
    @State var task = taskapeTask(
        name: "Complete project",
        taskDescription: "Finish all the views and connect them",
        author: "shevlfs",
        privacy: "private",
        flagStatus: true,
        flagColor: "#FF6B6B",
        flagName: "High"
    )

    return taskCardDetailView(detailIsPresent: .constant(true), task: task)
}
