import Alamofire
import Combine
import SwiftData
import SwiftDotenv
import SwiftUI

struct CreateGroupTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var group: taskapeGroup

    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var deadline: Date = .init().addingTimeInterval(24 * 60 * 60)
    @State private var hasDeadline: Bool = false
    @State private var difficulty: TaskDifficulty = .medium
    @State private var selectedMembers: [String] = []
    @State private var flagStatus: Bool = false
    @State private var flagColor: String? = nil
    @State private var flagName: String? = nil
    @State private var isCreating: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

    private var currentUserId: String {
        UserManager.shared.currentUserId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("task name")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextField("", text: $taskName)
                            .placeholder(when: taskName.isEmpty) {
                                Text("enter task name")
                                    .foregroundColor(.gray)
                                    .font(.pathway(16))
                            }
                            .font(.pathway(16))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("description")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextEditor(text: $taskDescription)
                            .placeholder(when: taskDescription.isEmpty) {
                                Text("describe what needs to be done")
                                    .foregroundColor(.gray)
                                    .font(.pathway(16))
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                            }
                            .font(.pathway(16))
                            .padding()
                            .frame(height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasDeadline) {
                            Text("set deadline")
                                .font(.pathway(14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if hasDeadline {
                            DatePicker(
                                "deadline",
                                selection: $deadline,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .font(.pathway(16))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("difficulty")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Picker("difficulty", selection: $difficulty) {
                            Text("small").tag(TaskDifficulty.small)
                            Text("medium").tag(TaskDifficulty.medium)
                            Text("large").tag(TaskDifficulty.large)
                        }
                        .pickerStyle(.segmented)
                        .font(.pathway(16))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("assign to")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Button(action: {}) {
                            HStack {
                                Text(selectedMembers.isEmpty ? "select members" : "\(selectedMembers.count) members selected")
                                    .font(.pathway(16))
                                    .foregroundColor(selectedMembers.isEmpty ? .gray : .primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $flagStatus) {
                            Text("set priority")
                                .font(.pathway(14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if flagStatus {
                            HStack {
                                Button(action: {
                                    flagColor = "#FF6B6B"
                                    flagName = "high priority"
                                }) {
                                    HStack {
                                        if let colorHex = flagColor {
                                            Circle()
                                                .fill(Color(hex: colorHex))
                                                .frame(width: 20, height: 20)

                                            Text(flagName ?? "priority")
                                                .font(.pathway(16))
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("select priority")
                                                .font(.pathway(16))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color(UIColor.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()

                    Button(action: {
                        createTask()
                    }) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                        } else {
                            Text("create task")
                                .font(.pathway(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(taskName.isEmpty ? Color.gray : Color.taskapeOrange)
                    )
                    .padding(.horizontal)
                    .disabled(isCreating || taskName.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("new task")
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
            .alert("error", isPresented: $showError) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "an error occurred")
            }
        }
    }

    private func createTask() {
        guard !taskName.isEmpty else { return }

        isCreating = true

        let newTask = taskapeTask(
            id: UUID().uuidString,
            user_id: currentUserId,
            name: taskName,
            taskDescription: taskDescription,
            author: currentUserId,
            privacy: PrivacySettings(level: .group),
            group: group.name,
            group_id: group.id,
            assignedToTask: selectedMembers,
            task_difficulty: difficulty,
            flagStatus: flagStatus,
            flagColor: flagColor,
            flagName: flagName
        )

        if hasDeadline {
            newTask.deadline = deadline
        }

        Task {
            if let success = await submitTask(task: newTask) {
                if success {
                    await MainActor.run {
                        modelContext.insert(newTask)
                        group.tasks.append(newTask)

                        try? modelContext.save()

                        isCreating = false
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        isCreating = false
                        errorMessage = "failed to create task, please try again"
                        showError = true
                    }
                }
            } else {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "failed to create task, please try again"
                    showError = true
                }
            }
        }
    }

    private func submitTask(task: taskapeTask) async -> Bool? {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            return nil
        }

        let deadlineString: String? = task.deadline?.ISO8601Format()

        let submission = TaskSubmission(
            id: task.id,
            user_id: task.user_id,
            name: task.name,
            description: task.taskDescription,
            deadline: deadlineString,
            author: task.author,
            group: task.group,
            group_id: task.group_id,
            assigned_to: task.assignedToTask,
            difficulty: task.task_difficulty.rawValue,
            is_completed: task.completion.isCompleted,
            custom_hours: task.custom_hours,
            privacy_level: task.privacy.level.rawValue,
            privacy_except_ids: task.privacy.exceptIDs,
            flag_status: task.flagStatus,
            flag_color: task.flagColor,
            flag_name: task.flagName,
            display_order: task.displayOrder,
            proof_needed: task.proofNeeded ?? false,
            proof_description: task.proofDescription,
            requires_confirmation: task.completion.requiresConfirmation,
            is_confirmed: task.completion.isConfirmed
        )

        let request = BatchTaskSubmissionRequest(
            tasks: [submission],
            token: token
        )

        do {
            let result = await AF.request(
                "\(Dotenv["RESTAPIENDPOINT"]!.stringValue)/submitTasksBatch",
                method: .post,
                parameters: request,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .serializingDecodable(BatchTaskSubmissionResponse.self)
            .response

            switch result.result {
            case let .success(response):
                return response.success
            case .failure:
                return false
            }
        } catch {
            return false
        }
    }
}
