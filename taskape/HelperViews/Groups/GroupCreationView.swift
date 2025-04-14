

import SwiftData
import SwiftUI

struct GroupCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var groupManager = GroupManager.shared

    @State private var groupName: String = ""
    @State private var groupDescription: String = ""
    @State private var groupColor: Color = .taskapeOrange
    @State private var isCreating: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var createdGroup: taskapeGroup? = nil

    private let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .mint, .cyan, .indigo, .teal, .brown,
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("group name")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextField("", text: $groupName)
                            .placeholder(when: groupName.isEmpty) {
                                Text("enter group name")
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

                        TextEditor(text: $groupDescription).scrollContentBackground(.hidden)
                            .font(.pathway(16))
                            .padding()
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                    }

                    Spacer()

                    Button(action: {
                        createGroup()
                    }) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                        } else {
                            Text("create group")
                                .font(.pathway(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(groupName.isEmpty ? Color.gray : Color.taskapeOrange)
                    )
                    .padding(.horizontal)
                    .disabled(isCreating || groupName.isEmpty)
                    .padding(.top, 16)
                }
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("create group").font(.pathway(16))
                }
            }
            .alert("error", isPresented: $showError) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "an error occurred")
            }
        }
    }

    private func createGroup() {
        guard !groupName.isEmpty else { return }

        isCreating = true

        Task {
            let colorHex = groupColor.toHex()

            if let newGroup = await groupManager.createGroup(
                name: groupName,
                description: groupDescription,
                color: colorHex,
                context: modelContext
            ) {
                await MainActor.run {
                    isCreating = false
                    createdGroup = newGroup
                }
            } else {
                await MainActor.run {
                    isCreating = false
                    errorMessage = "failed to create group, please try again"
                    showError = true
                }
            }
        }
    }
}

extension TextEditor {
    func placeholder(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> some View) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    GroupCreationView()
        .modelContainer(for: taskapeGroup.self, inMemory: true)
}
