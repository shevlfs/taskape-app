import SwiftData
import SwiftUI

struct taskCard: View {
    @Bindable var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var appearAnimation = false
    @State private var isAnimating: Bool = false
    @State private var foregroundColor: Color = Color.primary
    @State private var selectedPrivacyLevel: PrivacySettings.PrivacyLevel =
        .everyone
    @State private var disappearAnimation: Bool = false
    @State private var shouldShow: Bool = true
    @State var labels: [TaskFlag] = []


    @Environment(\.modelContext) var modelContext
    @FocusState var isFocused: Bool


    var onCompletionAnimationFinished: ((taskapeTask) -> Void)?

    @State var newCompletionStatus: Bool = false

    private func getTaskColor(flagColor: String?, newCompletionStatus: Bool)
        -> Color
    {
        let baseColor: Color = {
            if flagColor != nil && task.flagName != "" {
                return Color(hex: flagColor!)
            }
            return Color.taskapeOrange
        }()
        let opacity: Double = newCompletionStatus ? 0.5 : 0.8
        return baseColor.opacity(opacity)
    }

    var body: some View {
        HStack(spacing: 0) {
            CheckBoxView(task: task, newCompletionStatus: $newCompletionStatus)
                .modelContext(modelContext)
                .padding(.trailing, 5)
                .onChange(of: task.completion.isCompleted) {
                    oldValue, newValue in
                    if oldValue != newValue {
                        newCompletionStatus.toggle()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = true
                        }


                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isAnimating = false
                            }


                            if newValue == true && oldValue == false {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    disappearAnimation = true
                                }


                                DispatchQueue.main.asyncAfter(
                                    deadline: .now() + 0.5
                                ) {
                                    withAnimation {
                                        shouldShow = false
                                    }


                                    onCompletionAnimationFinished?(task)
                                }
                            }
                        }
                    }
                }

            Button(action: { detailIsPresent.toggle() }) {
                HStack {
                    Group {
                        HStack {
                            if !task.name.isEmpty {
                                Text(" \(task.name)")
                                    .font(.pathwayBold(15))
                                    .padding()
                                    .foregroundStyle(
                                        newCompletionStatus
                                            ? Color.white.opacity(0.7)
                                            : Color.white
                                    )
                                    .strikethrough(newCompletionStatus)

                            } else {
                                Text(" new to-do")
                                    .font(.pathwayBold(15))
                                    .padding()
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()

                            if !detailIsPresent {
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .frame(width: 5, height: 10)
                                    .foregroundColor(
                                        newCompletionStatus
                                            ? Color.white.opacity(0.7)
                                            : Color.white
                                    )
                                    .padding(.trailing, 20)
                                    .animation(
                                        Animation.easeInOut(duration: 0.25),
                                        value: detailIsPresent
                                    )
                            } else {
                                Image(systemName: "chevron.up")
                                    .resizable()
                                    .frame(width: 10, height: 5)
                                    .foregroundColor(
                                        newCompletionStatus
                                            ? Color.white.opacity(0.7)
                                            : Color.white
                                    )
                                    .padding(.trailing, 20)
                                    .transition(.opacity)
                                    .animation(
                                        Animation.easeInOut(duration: 0.25),
                                        value: detailIsPresent
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                getTaskColor(
                                    flagColor: task.flagColor,
                                    newCompletionStatus: newCompletionStatus
                                )
                            )
                            .stroke(.regularMaterial, lineWidth: 1)
                            .blur(radius: 0.25)
                    )
                    .completedTaskStyle(
                        isCompleted: newCompletionStatus,
                        isAnimating: isAnimating,
                        requiresConfirmation: task.completion
                            .requiresConfirmation
                    )
                    .padding(.leading, 5)
                    .padding(.trailing, 15)
                }
                .onAppear {
                    selectedPrivacyLevel = task.privacy.level

                    if newCompletionStatus && !isAnimating {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isAnimating = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $detailIsPresent) {
                taskCardDetailView(
                    detailIsPresent: $detailIsPresent,
                    task: task
                ).onDisappear {
                    saveTask()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }.onAppear { newCompletionStatus = task.completion.isCompleted }
            .opacity(disappearAnimation ? 0 : 1)
            .offset(x: disappearAnimation ? 50 : 0)
            .frame(height: shouldShow ? nil : 0, alignment: .top)
            .opacity(shouldShow ? 1 : 0)
    }

    func saveTask() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving task locally: \(error)")
        }

        print("saving edited task")

        Task {
            await syncTaskChanges(task: task)
        }
    }
}


extension taskCard {

    init(
        task: taskapeTask,
        onCompletionAnimationFinished: ((taskapeTask) -> Void)? = nil
    ) {
        self.task = task
        self.onCompletionAnimationFinished = onCompletionAnimationFinished
        self._shouldShow = State(initialValue: true)
        self._disappearAnimation = State(initialValue: false)
    }
}


struct CompletedTaskModifier: ViewModifier {
    let isCompleted: Bool
    let isAnimating: Bool
    let requiresConfirmation: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isCompleted ? 0.7 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        requiresConfirmation ? Color.yellow : Color.clear,
                        lineWidth: 1
                    )
                    .fill(Color.black.opacity(isCompleted ? 0.1 : 0))
                    .allowsHitTesting(false)
            )
            .overlay(
                GeometryReader { geometry in
                    if isCompleted {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: 1)
                            .offset(y: geometry.size.height / 2)
                            .scaleEffect(
                                x: isAnimating ? 1 : 0, anchor: .leading
                            )
                            .animation(
                                .easeInOut(duration: 0.3), value: isAnimating)
                    } else if requiresConfirmation {

                    }
                }
            )
    }
}

extension View {
    func completedTaskStyle(
        isCompleted: Bool, isAnimating: Bool, requiresConfirmation: Bool = false
    ) -> some View {
        self.modifier(
            CompletedTaskModifier(
                isCompleted: isCompleted, isAnimating: isAnimating,
                requiresConfirmation: requiresConfirmation))
    }
}

#Preview {

    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: taskapeTask.self, configurations: config)


        let designTask = taskapeTask(
            name: "Design new UI",
            taskDescription: "Create mockups in Figma",
            author: "shevlfs",
            privacy: PrivacySettings(level: .everyone)
        )

        let completedTask = taskapeTask(
            name: "Implement animations",
            taskDescription: "Add spring animations to cards",
            author: "shevlfs",
            privacy: PrivacySettings(level: .everyone)
        )
        completedTask.completion.isCompleted = true

        let flaggedTask = taskapeTask(
            name: "High priority task",
            taskDescription: "This is flagged as important",
            author: "shevlfs",
            privacy: PrivacySettings(level: .everyone),
            flagStatus: true,
            flagColor: "#FF6B6B"
        )

        let emptyTask = taskapeTask(
            name: "",
            taskDescription: "Fix back button not working properly",
            author: "shevlfs",
            privacy: PrivacySettings(level: .noone)
        )


        container.mainContext.insert(designTask)
        container.mainContext.insert(completedTask)
        container.mainContext.insert(flaggedTask)
        container.mainContext.insert(emptyTask)


        return VStack(spacing: 20) {
            ScrollView {
                VStack(spacing: 10) {
                    taskCard(task: designTask)
                    taskCard(task: completedTask)
                    taskCard(task: flaggedTask)
                    taskCard(task: emptyTask)
                }
                .padding()
            }
        }
        .padding()
        .preferredColorScheme(.dark)
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
