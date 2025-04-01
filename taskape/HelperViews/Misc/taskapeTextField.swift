






import SwiftUI

struct taskapeTextField: View {
    @State var current_string: String = ""
    @State var placeholder: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {
            isFocused = true
        }) {
            TextField(
                placeholder,
                text: $current_string
            )
            .focused($isFocused)
            .textFieldStyle(.automatic)
            .accentColor(.taskapeOrange)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .font(.pathwayBlack(20))
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
                    .stroke(.thinMaterial, style: StrokeStyle(lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    taskapeTextField()
}
