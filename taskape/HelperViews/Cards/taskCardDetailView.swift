//
//  taskCardDetailView.swift
//  taskape
//
//  Created by shevlfs on 3/6/25.
//

import SwiftData
import SwiftUI

struct taskCardDetailView: View {
    @Binding var detailIsPresent: Bool
    @Bindable var task: taskapeTask
    @State private var selectedPrivacyLevel: PrivacySettings.PrivacyLevel =
        .everyone
    @State private var foregroundColor: Color = Color.primary

    @Environment(\.modelContext) var modelContext

    @FocusState var isFocused: Bool
    var body: some View {
        Group {
            VStack {
                Button(action: { detailIsPresent.toggle() }) {
                    Image(systemName: "chevron.down")
                }.buttonStyle(PlainButtonStyle())
                HStack {
                    Group {
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

            }.padding(.top, 20)
            Spacer()
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    // taskCardDetailView()
}
