import SwiftUI

struct CheckBoxView: View {
    @Bindable var task: taskapeTask
    @State private var isAnimating: Bool = false
    @Binding var newCompletionStatus: Bool
    @State private var showProofSubmission: Bool = false
    @State private var proofSubmitted: Bool = false
    @Environment(\.modelContext) var modelContext

    private func getTaskColor(flagColor: String?)
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
        Button(action: {

            if task.proofNeeded == true && !proofSubmitted {
                showProofSubmission = true
            } else {

                newCompletionStatus.toggle()


                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAnimating = true
                }


                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAnimating = false
                    }



                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {

                        task.completion.isCompleted = newCompletionStatus

                        saveTask()
                    }
                }
            }
        }) {
            ZStack {

                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        newCompletionStatus
                            ? getTaskColor(flagColor: task.flagColor) : Color.gray.opacity(0.7),
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                newCompletionStatus
                                ? getTaskColor(flagColor: task.flagColor)
                                    .opacity(0.3)
                                    : Color.clear)
                    )


                if newCompletionStatus {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(getTaskColor(flagColor: task.flagColor))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                }
            }
            .padding(.leading, 8)
            .contentShape(Circle())
            .scaleEffect(isAnimating ? 1.2 : 1.0)
        }
        .onChange(of: task.completion.isCompleted) { _, newValue in

            newCompletionStatus = newValue
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showProofSubmission) {
            ProofSubmissionView(
                task: task,
                isPresented: $showProofSubmission,
                proofSubmitted: $proofSubmitted
            )
                .modelContext(modelContext)
        }
    }

    func saveTask() {
        do {
            try modelContext.save()


            let userId = task.user_id

            updateWidgetWithTasks(userId: userId, modelContext: modelContext)

        } catch {
            print("Error saving task locally: \(error)")
        }

        print("saving edited task")

        Task {
            await syncTaskChanges(task: task)
        }
    }
}


struct TaskCardWithCheckbox: View {
    @Bindable var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var isAnimating: Bool = false
    @State private var newCompletionStatus: Bool = false

    @Binding var labels: [TaskFlag]

    @Environment(\.colorScheme) var colorScheme

    @Environment(\.modelContext) var modelContext

    func getTaskTextColor(flagColor: String?, newCompletionStatus: Bool)
        -> Color
    {
        if flagColor != nil && task.flagName != "" {
            return Color(hex: flagColor!).contrastingTextColor(in: colorScheme)
        } else {
            return newCompletionStatus ? Color.white.opacity(0.7) : Color.white
        }
    }

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
                .onChange(of: newCompletionStatus) {
                    oldValue, newValue in
                    if oldValue != newValue {
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

            Button(action: { detailIsPresent.toggle() }) {
                HStack {
                    VStack {
                        HStack {
                            if !task.name.isEmpty {
                                Text(" \(task.name)")
                                    .font(.pathwayBold(15))
                                    .padding()
                                    .foregroundStyle(
                                        getTaskTextColor(
                                            flagColor: task.flagColor,
                                            newCompletionStatus:
                                                newCompletionStatus
                                        )
                                    )
                                    .strikethrough(newCompletionStatus)

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
                                    newCompletionStatus
                                        ? Color.white.opacity(0.7) : Color.white
                                )
                                .padding(.trailing, 20)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                getTaskColor(
                                    flagColor: task.flagColor,
                                    newCompletionStatus: newCompletionStatus)
                            )
                            .stroke(.regularMaterial, lineWidth: 1)
                            .blur(radius: 0.25)
                    )
                    .completedTaskStyle(
                        isCompleted: newCompletionStatus,
                        isAnimating: isAnimating, requiresConfirmation: task.completion.requiresConfirmation
                    )
                    .padding(.leading, 5)
                    .padding(.trailing, 5)
                }
            }
            .sheet(isPresented: $detailIsPresent) {
                taskCardDetailView(
                    detailIsPresent: $detailIsPresent,
                    task: task, labels: labels
                ).transition(.opacity)
                    .animation(
                        Animation.easeInOut(duration: 0.25),
                        value: detailIsPresent
                    ).onDisappear {
                        saveTask()
                        task.syncWithWidget()
                        TaskNotifier.notifyTasksUpdated()
                    }
            }.onAppear {

                newCompletionStatus = task.completion.isCompleted
            }.onChange(of: task.completion.isCompleted) { _, newValue in

                newCompletionStatus = newValue
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
