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
            .frame(minHeight: 100, maxHeight: 170)
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
        (label: "important", color: "#FF6B6B"),
        (label: "work", color: "#FFD166"),
        (label: "study", color: "#06D6A0"),
        (label: "life", color: "#118AB2"),
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
                            priorityOptions.first { $0.color == colorHex }?
                            .label ?? flagName ?? "Custom"
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
                        .foregroundColor(Color.taskapeOrange).padding(
                            .trailing, 12)
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
}

// COMPONENT 5.1: Priority picker content
struct PriorityPickerContent: View {
    @Binding var flagStatus: Bool
    @Binding var flagColor: String?
    @Binding var flagName: String?
    let priorityOptions: [(label: String, color: String)]
    @Binding var showPicker: Bool

    @State private var isAddingCustomLabel: Bool = false
    @State private var customColor: Color = .orange
    @State private var customLabelName: String = ""

    private let defaultColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
    ]

    var body: some View {
        if isAddingCustomLabel {
            VStack(alignment: .center, spacing: 0) {
                HStack {
                    Button(action: {
                        isAddingCustomLabel = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 10)
                    Spacer()

                    Text("new label")
                        .font(.pathway(17))
                        .fontWeight(.medium)
                        .padding(.top, 16)
                        .padding(.bottom, 12).offset(x: -10)

                    Spacer()
                }

                Divider()
                    .padding(.bottom, 8)

                Spacer()

                // Label name field
                Text("label name:")
                    .font(.pathway(16))
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                TextField("enter label name", text: $customLabelName)
                    .autocorrectionDisabled()
                    .font(.pathway(16))
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Text("label color:")
                    .font(.pathway(16))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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
                .padding(.horizontal)
                .padding(.bottom, 24)

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
                        .padding(.vertical, 14)
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
                                        .frame(width: 18, height: 18)

                                    Text(option.label)
                                        .font(.pathway(17))
                                        .padding(.leading, 12)

                                    Spacer()

                                    if flagStatus && flagColor == option.color
                                        && flagName == option.label
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
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18)).frame(
                                        width: 18, height: 18)

                                Text("add custom label")
                                    .font(.pathway(17))
                                    .foregroundColor(.orange)
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

    var body: some View {
        HStack {
            Text("privacy").font(.pathway(17))
            Spacer()

            Picker("privacy", selection: $privacyLevel) {
                Text("everyone").tag(PrivacySettings.PrivacyLevel.everyone)
                Text("no one").tag(PrivacySettings.PrivacyLevel.noone)
                Text("friends only").tag(
                    PrivacySettings.PrivacyLevel.friendsOnly)
                Text("group").tag(PrivacySettings.PrivacyLevel.group)
                Text("everyone except...").tag(
                    PrivacySettings.PrivacyLevel.except)
            }.font(.pathwayBold(17))
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
                //DetailViewHeader(detailIsPresent: $detailIsPresent)

                // Component 2: Task name field
                TaskNameField(
                    name: $task.name, flagColor: $task.flagColor,
                    flagName: $task.flagName)

                // Component 3: Task description field
                TaskDescriptionField(
                    description: $task.taskDescription, isFocused: _isFocused)

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
