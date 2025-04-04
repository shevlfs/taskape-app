import SwiftUI

struct TaskFlagButton: View {
    @Bindable var task: taskapeTask
    @State private var showFlagPicker = false

    private let flagOptions = [
        (name: "High Priority", color: "#FF6B6B"),
        (name: "Medium Priority", color: "#FFD166"),
        (name: "Low Priority", color: "#06D6A0"),
        (name: "Info", color: "#118AB2"),
        (name: "Planning", color: "#073B4C"),
    ]

    var body: some View {
        Button(action: {
            if task.flagStatus {
                showFlagPicker.toggle()
            } else {
                withAnimation {
                    task.toggleFlag()
                    notifyFlagChanged()
                }
            }
        }) {
            Image(systemName: task.flagStatus ? "flag.fill" : "flag")
                .font(.system(size: 16))
                .foregroundColor(getFlagColor())
                .padding(8)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showFlagPicker) {
            VStack(spacing: 12) {
                Text("Priority")
                    .font(.pathway(18))
                    .padding(.top)

                ForEach(flagOptions, id: \.color) { option in
                    Button(action: {
                        withAnimation {
                            task.setFlag(color: option.color, name: option.name)
                            showFlagPicker = false
                            notifyFlagChanged()
                        }
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: option.color))
                                .frame(width: 20, height: 20)
                            Text(option.name)
                                .font(.pathway(16))
                            Spacer()
                            if task.flagColor == option.color {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Divider()

                Button(action: {
                    task.toggleFlag()
                    showFlagPicker = false
                    notifyFlagChanged()
                }) {
                    Text("Remove Flag")
                        .font(.pathway(16))
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .padding(.bottom)
            }
            .frame(width: 280)
            .padding()
        }
    }

    private func getFlagColor() -> Color {
        if task.flagStatus, let colorHex = task.flagColor {
            return Color(hex: colorHex)
        }
        return Color.gray
    }

    private func notifyFlagChanged() {
        FlagManager.shared.flagChanged()
    }
}
