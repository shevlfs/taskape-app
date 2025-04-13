import SwiftData
import SwiftUI

struct GroupJoinView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var groupManager = GroupManager.shared

    @State private var inviteCode: String = ""
    @State private var isJoining: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var joinedGroup: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.taskapeOrange)
                    .padding(.top, 40)

                Text("join a group")
                    .font(.pathwayBold(24))
                    .padding(.top, 10)

                Text("enter the invite code shared with you to join a group")
                    .font(.pathway(16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text("invite code")
                        .font(.pathway(14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    TextField("", text: $inviteCode)
                        .placeholder(when: inviteCode.isEmpty) {
                            Text("enter invite code")
                                .foregroundColor(.gray)
                                .font(.pathway(16))
                        }
                        .font(.pathway(16))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                Spacer()

                Button(action: {
                    joinGroup()
                }) {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    } else {
                        Text("join group")
                            .font(.pathway(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            inviteCode.isEmpty
                                ? Color.gray : Color.taskapeOrange)
                )
                .padding(.horizontal)
                .disabled(isJoining || inviteCode.isEmpty)
                .padding(.bottom, 30)
            }
            .navigationTitle("join group")
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
            .alert("success", isPresented: $joinedGroup) {
                Button("ok", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("you have successfully joined the group")
            }
        }
    }

    private func joinGroup() {
        guard !inviteCode.isEmpty else { return }

        isJoining = true

        Task {
            let success = await groupManager.acceptGroupInvitation(
                inviteId: inviteCode)

            await MainActor.run {
                isJoining = false

                if success {
                    groupManager.loadUserGroups(context: modelContext)
                    joinedGroup = true
                } else {
                    errorMessage =
                        "failed to join group. please check the invite code and try again"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    GroupJoinView()
        .modelContainer(for: taskapeGroup.self, inMemory: true)
}
