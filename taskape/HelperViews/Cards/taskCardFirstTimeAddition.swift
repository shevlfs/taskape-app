import SwiftData
import SwiftUI

struct taskCardFirstTimeAddition: View {
    @Binding var task: taskapeTask
    @State var detailIsPresent: Bool = false
    @State private var appearAnimation = false
    @State private var foregroundColor: Color = Color.primary
    @State private var selectedPrivacyLevel: PrivacySettings.PrivacyLevel =
        .everyone

    @State var firstLaunch: Bool = false

    @FocusState var isFocused: Bool

    var body: some View {
        Button(action: { detailIsPresent.toggle() }) {
            HStack {
                VStack {
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
            .opacity(appearAnimation ? 1 : 0)
            .offset(x: appearAnimation ? 0 : -50)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    appearAnimation = true
                }
                selectedPrivacyLevel = task.privacy.level
            }
        }
        .sheet(isPresented: $detailIsPresent) {
            VStack {
                VStack {
                    Button(action: { detailIsPresent.toggle() }) {
                        Image(systemName: "chevron.down")
                    }.buttonStyle(PlainButtonStyle())
                    HStack {
                        VStack {
                            HStack {
                                TextField(
                                    "what needs to be done?", text: $task.name
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
                        }.background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.taskapeOrange.opacity(0.8))
                                .stroke(.regularMaterial, lineWidth: 1).blur(
                                    radius: 0.5)
                        ).padding()
                    }

                    TextEditor(text: $task.taskDescription)
                        .font(.pathway(17)).focused($isFocused)
                        .foregroundColor(foregroundColor)
                        .padding()
                        .scrollContentBackground(.hidden)
                        .accentColor(Color.taskapeOrange)
                        .background(
                            RoundedRectangle(cornerRadius: 30).fill(
                                Color(UIColor.secondarySystemBackground))
                        )
                        .frame(maxHeight: 150)
                        .padding(.horizontal)

                    // DatePicker for the task deadline
                    DatePicker(
                        "due date",
                        selection: Binding(
                            get: { task.deadline ?? Date() },
                            set: { task.deadline = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    ).font(.pathway(17))
                        .padding()
                        .accentColor(Color.taskapeOrange)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)

                    HStack {
                        Text("privacy ").font(.pathway(17))
                        Spacer()

                        Picker("privacy", selection: $selectedPrivacyLevel) {
                            Text("everyone").tag(
                                PrivacySettings.PrivacyLevel.everyone)
                            Text("no one").tag(
                                PrivacySettings.PrivacyLevel.noone)
                        }
                        .pickerStyle(MenuPickerStyle()).accentColor(
                            Color.taskapeOrange
                        )
                        .onChange(of: selectedPrivacyLevel) {
                            task.privacy.level = selectedPrivacyLevel
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    if firstLaunch {
                        Text(
                            "privacy fine-tuning will be available as soon\nas you connect with your friends on \(Text("taskape").font(.pathway(13)).foregroundColor(Color.taskapeOrange))"
                        ).multilineTextAlignment(.center).font(
                            .pathwayItalic(13)
                        ).padding(.horizontal)
                    }

                }.padding(.top, 20)
                Spacer()
            }
            .presentationDetents([.medium])
        }
        .buttonStyle(PlainButtonStyle())
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
                        taskCardFirstTimeAddition(
                            task: .constant(
                                taskapeTask(
                                    name: "Design new UI",
                                    taskDescription: "Create mockups in Figma",
                                    author: "shevlfs",
                                    privacy: "private"
                                )
                            ),
                            firstLaunch: true  // Hex color for orange
                        )

                        let completedTask = taskapeTask(
                            name: "Implement animations",
                            taskDescription: "Add spring animations to cards",
                            author: "shevlfs",
                            privacy: "public"
                        )

                        taskCardFirstTimeAddition(
                            task: .constant(completedTask)
                        )

                        taskCardFirstTimeAddition(
                            task: .constant(
                                taskapeTask(
                                    name: "",
                                    taskDescription:
                                        "Fix back button not working properly",
                                    author: "shevlfs",
                                    privacy: "private"
                                )
                            )
                        )

                        taskCardFirstTimeAddition(
                            task: .constant(
                                taskapeTask(
                                    name: "Write documentation",
                                    taskDescription: "",
                                    author: "collaborator",
                                    privacy: "team"
                                )
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
