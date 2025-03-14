//
//  taskCard.swift
//  taskape
//
//  Created by shevlfs on 3/6/25.
//

import SwiftUI

struct taskCard: View {
    @Bindable var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var appearAnimation = false
    @State private var foregroundColor: Color = Color.primary
    @State private var selectedPrivacyLevel: PrivacySettings.PrivacyLevel =
        .everyone

    @Environment(\.modelContext) var modelContext
    @FocusState var isFocused: Bool

    var body: some View {
        Button(action: { detailIsPresent.toggle() }) {
            HStack {
                Group {
                    HStack {
                        if !task.name.isEmpty {
                            Text(" \(task.name)")
                                .font(.pathwayBold(15))
                                .padding()
                                .foregroundStyle(Color.white)

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
                                .foregroundColor(Color.white).padding(
                                    .trailing, 20
                                )
                                .animation(
                                    Animation
                                        .easeInOut(
                                            duration: 0.25
                                        ),
                                    value: detailIsPresent
                                )
                        } else {
                            Image(systemName: "chevron.up")
                                .resizable()
                                .frame(width: 10, height: 5)
                                .foregroundColor(Color.white)
                                .padding(.trailing, 20)
                                .transition(.opacity)
                                .animation(
                                    Animation
                                        .easeInOut(
                                            duration: 0.25
                                        ),
                                    value: detailIsPresent
                                )
                        }

                    }
                }.background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.taskapeOrange.opacity(0.8))
                        .stroke(.regularMaterial, lineWidth: 1).blur(
                            radius: 0.25)
                ).padding(.leading, 5).padding(.trailing, 15)
            }
//            .opacity(appearAnimation ? 1 : 0)
//            .offset(x: appearAnimation ? 0 : -50)
            .onAppear {
//                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
//                    appearAnimation = true
//                }
                selectedPrivacyLevel = task.privacy.level
            }
        }
        .sheet(isPresented: $detailIsPresent) {
            taskCardDetailView(
                detailIsPresent: $detailIsPresent,
                task: task
            ).onDisappear(){
                saveTask()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    func saveTask() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving task locally: \(error)")
        }

        print("saving edited task")

        Task {
            await syncTaskChanges(
                task: task)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var sampleTask = taskapeTask(
            name: "Complete SwiftUI project",
            taskDescription: "Finish all the views and connect them",
            author: "shevlfs",
            privacy: "private"
        )

        var body: some View {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 10) {
                        taskCard(
                            task:
                                taskapeTask(
                                    name: "Design new UI",
                                    taskDescription: "Create mockups in Figma",
                                    author: "shevlfs",
                                    privacy: "private"
                                )

                        )

                        // Sample completed task
                        let completedTask = taskapeTask(
                            name: "Implement animations",
                            taskDescription: "Add spring animations to cards",
                            author: "shevlfs",
                            privacy: "public"
                        )

                        taskCard(
                            task: completedTask
                        )

                        taskCard(
                            task:
                                taskapeTask(
                                    name: "",
                                    taskDescription:
                                        "Fix back button not working properly",
                                    author: "shevlfs",
                                    privacy: "private"
                                )

                        )

                        taskCard(
                            task:
                                taskapeTask(
                                    name: "Write documentation",
                                    taskDescription: "",
                                    author: "collaborator",
                                    privacy: "team"
                                )

                        )
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.1))
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
