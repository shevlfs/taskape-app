import SwiftUI

struct taskapeColorPicker: View {
    @Binding var selectedColor: String
    @State private var customColor = Color.white

    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(TaskapeColor.presetColors) { colorItem in
                    Circle()
                        .fill(colorItem.color)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white,
                                    lineWidth: selectedColor == colorItem.hex
                                        ? 3 : 0
                                )
                        )
                        .shadow(radius: 2)
                        .onTapGesture {
                            selectedColor = colorItem.hex
                        }
                }

                ColorPicker("", selection: $customColor)
                    .labelsHidden()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .shadow(radius: 2)
                    .onChange(of: customColor) {
                        selectedColor = customColor.toHex()
                    }
            }
            .padding()
        }
    }
}

struct ProfileCreationColorSelectionView: View {
    @Binding var color: String
    @Binding var path: NavigationPath
    @Binding var progress: Float

    var body: some View {
        VStack {
            ProfileCreationProgressBar(progress: $progress)
            Text("what is your favorite color?")
                .multilineTextAlignment(.center)
                .font(.pathway(30))
                .padding()

            Spacer()

            taskapeColorPicker(selectedColor: $color)

            Spacer()

            Button(
                action: {
                    if color.isEmpty {
                        color = TaskapeColor.presetColors.first!.hex
                    }

                    UserDefaults.standard.set(color, forKey: "color")
                    path.append("pfp_selection")
                    progress += 1 / 5

                }) {
                    taskapeContinueButton()
                }.buttonStyle(PlainButtonStyle())

            Text("it will be displayed as a background\n on your profile")
                .multilineTextAlignment(.center)
                .font(.pathwayItalic(16))
                .padding()
        }
    }
}

#Preview {
    @Previewable @State var color = ""
    @Previewable @State var path = NavigationPath()
    ProfileCreationColorSelectionView(
        color: $color,
        path: $path, progress: .constant(0.3)
    )
}
