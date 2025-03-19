import SwiftUI

struct CheckBoxView: View {
    @Bindable var task: taskapeTask
    @State private var isAnimating: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAnimating = true
            }

            // Delay the actual completion status change to allow animation to play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                task.completion.isCompleted.toggle()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7))
                    {
                        isAnimating = false
                    }
                }
            }
        }) {
            ZStack {
                // Outer circle
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        task.completion.isCompleted
                            ? Color.taskapeOrange : Color.gray.opacity(0.7),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                task.completion.isCompleted
                                    ? Color.taskapeOrange.opacity(0.3)
                                    : Color.clear)
                    )

                // Checkmark
                if task.completion.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.taskapeOrange)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                }
            }
            .padding(.leading, 8)
            .contentShape(Circle())
            .scaleEffect(isAnimating ? 1.2 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Modifier to apply the completed task style
struct CompletedTaskModifier: ViewModifier {
    let isCompleted: Bool
    let isAnimating: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isCompleted ? 0.7 : 1.0)
            .overlay(
                Rectangle()
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

// Updated taskCard to incorporate the checkbox
struct TaskCardWithCheckbox: View {
    @Bindable var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var isAnimating: Bool = false

    @Environment(\.modelContext) var modelContext

    var body: some View {
        HStack(spacing: 0) {
            CheckBoxView(task: task)
                .onChange(of: task.completion.isCompleted) {
                    oldValue, newValue in
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
                                    .foregroundStyle(
                                        task.completion.isCompleted
                                            ? Color.white.opacity(0.7)
                                            : Color.white
                                    )
                                    .strikethrough(task.completion.isCompleted)

                            } else {
                                Text(" new to-do")
                                    .font(.pathwayBold(15))
                                    .padding()
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()

                            Image(systemName: "chevron.right")
                                .resizable()
                                .frame(width: 5, height: 10)
                                .foregroundColor(
                                    task.completion.isCompleted
                                        ? Color.white.opacity(0.7) : Color.white
                                )
                                .padding(.trailing, 20)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                task.completion.isCompleted
                                    ? Color.taskapeOrange.opacity(0.5)
                                    : Color.taskapeOrange.opacity(0.8)
                            )
                            .stroke(.regularMaterial, lineWidth: 1)
                            .blur(radius: 0.25)
                    )
                    .completedTaskStyle(
                        isCompleted: task.completion.isCompleted,
                        isAnimating: isAnimating
                    )
                    .padding(.leading, 5)
                    .padding(.trailing, 15)
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

#Preview {
    TaskCardWithCheckbox(
        task: taskapeTask(
            name: "Design new UI",
            taskDescription: "Create mockups in Figma",
            author: "shevlfs",
            privacy: "private"
        )
    )
}
