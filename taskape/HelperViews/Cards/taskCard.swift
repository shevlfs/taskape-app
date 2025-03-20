import SwiftUI
import SwiftData


struct taskCard: View {
    @Bindable var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var appearAnimation = false
    @State private var isAnimating: Bool = false
    @State private var foregroundColor: Color = Color.primary
    @State private var selectedPrivacyLevel: PrivacySettings.PrivacyLevel = .everyone

    @Environment(\.modelContext) var modelContext
    @FocusState var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            CheckBoxView(task: task).padding(.trailing, 5)
                .onChange(of: task.completion.isCompleted) { oldValue, newValue in
                    if oldValue != newValue {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = true
                        }

                        // Reset animation state after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isAnimating = false
                            }

                            // Save changes to the task
                            saveTask()
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
                                    .foregroundStyle(task.completion.isCompleted ? Color.white.opacity(0.7) : Color.white)
                                    .strikethrough(task.completion.isCompleted)

                            } else {
                                Text(" new to-do")
                                    .font(.pathwayBold(15))
                                    .padding()
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()

//                            if task.flagStatus {
//                                if let colorHex = task.flagColor {
//                                    Image(systemName: "flag.fill")
//                                        .foregroundColor(Color(hex: colorHex))
//                                        .font(.system(size: 14))
//                                        .padding(.trailing, 10)
//                                }
//                            }

                            if !detailIsPresent {
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .frame(width: 5, height: 10)
                                    .foregroundColor(task.completion.isCompleted ? Color.white.opacity(0.7) : Color.white)
                                    .padding(.trailing, 20)
                                    .animation(
                                        Animation.easeInOut(duration: 0.25),
                                        value: detailIsPresent
                                    )
                            } else {
                                Image(systemName: "chevron.up")
                                    .resizable()
                                    .frame(width: 10, height: 5)
                                    .foregroundColor(task.completion.isCompleted ? Color.white.opacity(0.7) : Color.white)
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
                            .fill(task.completion.isCompleted ?
                                  Color.taskapeOrange.opacity(0.5) :
                                  Color.taskapeOrange.opacity(0.8))
                            .stroke(.regularMaterial, lineWidth: 1)
                            .blur(radius: 0.25)
                    )
                    .completedTaskStyle(isCompleted: task.completion.isCompleted, isAnimating: isAnimating)
                    .padding(.leading, 5)
                    .padding(.trailing, 15)
                }
                .onAppear {
                    selectedPrivacyLevel = task.privacy.level
                    // Trigger animation if task is already completed
                    if task.completion.isCompleted && !isAnimating {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAnimating = true
                        }
                        // Reset after a delay
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
        }
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

// Fixed CompletedTaskModifier to properly apply greying out
struct CompletedTaskModifier: ViewModifier {
    let isCompleted: Bool
    let isAnimating: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isCompleted ? 0.7 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(isCompleted ? 0.1 : 0))
                    .allowsHitTesting(false)
            )
            .overlay(
                GeometryReader { geometry in
                    if isCompleted {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 2)
                            .offset(y: geometry.size.height / 2)
                            .scaleEffect(
                                x: isAnimating ? 1 : 0, anchor: .leading
                            )
                            .animation(
                                .easeInOut(duration: 0.3), value: isAnimating)
                    }
                }
            )
    }
}

extension View {
    func completedTaskStyle(isCompleted: Bool, isAnimating: Bool) -> some View {
        self.modifier(
            CompletedTaskModifier(
                isCompleted: isCompleted, isAnimating: isAnimating))
    }
}

#Preview {
    // Create a proper model container for preview
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: taskapeTask.self, configurations: config)

        // Create sample tasks in the container
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

        // Insert the tasks into the container
        container.mainContext.insert(designTask)
        container.mainContext.insert(completedTask)
        container.mainContext.insert(flaggedTask)
        container.mainContext.insert(emptyTask)

        // Return the preview with the sample tasks
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
            .background(Color.black.opacity(0.1))
        }
        .padding()
        .preferredColorScheme(.dark)
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
