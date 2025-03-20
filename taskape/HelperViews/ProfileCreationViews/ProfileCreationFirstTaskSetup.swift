import SwiftData
import SwiftUI

struct taskapeTaskField: View {
    @Binding var taskName: String

    var body: some View {
        TextField("what needs to be done?", text: $taskName)
            .padding(15)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled(true).autocapitalization(.none)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)
            .font(.pathway(18))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(.thinMaterial, lineWidth: 1)
            )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct taskapeTaskDescriptionField: View {
    @Binding var taskDescription: String

    var body: some View {
        TextField("any details? (optional)", text: $taskDescription)
            .padding(15)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled(true).autocapitalization(.none)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)
            .font(.pathway(16))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(.thinMaterial, lineWidth: 1)
            )
    }
}

struct ProfileCreationFirstTaskSetup: View {
    @Environment(\.modelContext) private var modelContext
    @Query var currentUser: [taskapeUser]

    @Binding var path: NavigationPath
    @Binding var progress: Float

    @Binding var userAlreadyExists: Bool

    @State var taskName: String = ""
    @State var taskDescription: String = ""
    @State var tasks: [taskapeTask] = []
    @State private var addTaskAnimation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0

    @EnvironmentObject private var appState: AppStateManager

    var userId: String? = nil

    func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
    }

    var body: some View {
        VStack {
            ProfileCreationProgressBar(progress: $progress)

            Text("anything you need to get done right now?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)
                    .allowsHitTesting(false)

                    Spacer()

                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground).opacity(0),
                            Color(.systemBackground),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity)
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scrollView"))
                                .origin.y
                        )
                    }
                    .frame(height: 0)

                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) {
                            index, _ in
                            HStack {
                                Text("•").font(.headline).padding(.leading, 10)
                                taskCardFirstTimeAddition(
                                    task: $tasks[index],
                                    firstLaunch: true
                                ).contextMenu {
                                    Button {
                                        tasks.remove(at: index)

                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }.transition(
                                .asymmetric(
                                    insertion: .opacity.combined(
                                        with: .scale(scale: 0.95)
                                    ).animation(
                                        .spring(
                                            response: 0.4,
                                            dampingFraction: 0.8)
                                    ),
                                    removal: .opacity.animation(
                                        .easeOut(duration: 0.2))
                                )
                            )

                            .id(tasks[index].id)
                        }.transition(
                            .asymmetric(
                                insertion: .opacity.combined(
                                    with: .scale(scale: 0.95)
                                ).animation(
                                    .spring(
                                        response: 0.4,
                                        dampingFraction: 0.8)
                                ),
                                removal: .opacity.animation(
                                    .easeOut(duration: 0.2))
                            )
                        )
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 6)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8),
                        value: tasks.count
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                scrollViewHeight = geo.size.height
                            }
                            .onChange(of: tasks.count) { _, _ in

                                scrollViewHeight = geo.size.height
                            }
                        }
                    )
                }
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)

            HStack(spacing: 16) {
                taskapeTaskField(taskName: $taskName)
                Button(action: {
                    if !taskName.isEmpty {
                        let uid =
                            userId ?? UserDefaults.standard.string(
                                forKey: "user_id") ?? ""
                        print("Creating task with user_id: \(uid)")

                        let newTask = taskapeTask(
                            id: UUID().uuidString,
                            user_id: uid,
                            name: taskName,
                            taskDescription: taskDescription,
                            author: currentUser.first?.handle ?? "",
                            privacy: PrivacySettings(level: .everyone)
                        )

                        withAnimation(
                            .spring(response: 0.3, dampingFraction: 0.85)
                        ) {
                            addTaskAnimation = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                addTaskAnimation = false
                            }
                        }

                        tasks.append(newTask)
                        taskName = ""
                        taskDescription = ""
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.pathway(18)).foregroundStyle(Color.white)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.taskapeOrange.opacity(0.8))
                        ).scaleEffect(addTaskAnimation ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(taskName.isEmpty)
            }

            Spacer()

            Button(
                action: {
                    if !tasks.isEmpty {
                        saveTasks()
                        UserDefaults.standard.set(true, forKey: "profileExists")
                        appState.login()
                        userAlreadyExists = true
                        progress = 1.0
                    }
                }) {
                    taskapeContinueButton()
                }.buttonStyle(.plain).disabled(tasks.isEmpty)

            Text("the work is mysterious and important")
                .multilineTextAlignment(.center)
                .font(.pathwayItalic(16))
                .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    func saveTasks() {
        print("saving tasks lol")
        if let user = currentUser.first {
            for task in tasks {
                task.user_id = userId ?? user.id
                modelContext.insert(task)
                user.tasks.append(task)
            }
            print("got user")

            do {
                try modelContext.save()
                var tasksToSubmit = tasks
                for i in 0..<tasksToSubmit.count {
                    tasksToSubmit[i].user_id = userId ?? user.id
                }

                Task {
                    let response = await submitTasksBatch(tasks: tasksToSubmit)
                    if let response = response, response.success {
                        print("All tasks successfully saved to server")
                        if response.task_ids.count == tasks.count {
                            for i in 0..<tasks.count {
                                tasks[i].id = response.task_ids[i]
                            }
                            try? modelContext.save()
                        }
                    } else {
                        print("Failed to save tasks to server")
                    }
                }
            } catch {
                print("Error saving tasks locally: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    @Previewable @State var progress: Float = 0.8
    ProfileCreationFirstTaskSetup(
        path: .constant(path),
        progress: .constant(progress),
        userAlreadyExists: .constant(false)
    )
    .modelContainer(for: [taskapeUser.self, taskapeTask.self], inMemory: true)
}
