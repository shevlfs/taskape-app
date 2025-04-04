

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

                        TextEditor(text: $groupDescription)
                            .placeholder(when: groupDescription.isEmpty) {
                                Text("describe your group")
                                    .foregroundColor(.gray)
                                    .font(.pathway(16))
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                            }
                            .font(.pathway(16))
                            .padding()
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("group color")
                            .font(.pathway(14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    Color.white,
                                                    lineWidth: groupColor == color ? 3 : 0
                                                )
                                        )
                                        .shadow(radius: 2)
                                        .onTapGesture {
                                            groupColor = color
                                        }
                                }
                            }
                            .padding()
                        }
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
            .navigationTitle("create group")
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
            .navigationDestination(item: $createdGroup) { group in
                GroupDetailView(group: group)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
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
