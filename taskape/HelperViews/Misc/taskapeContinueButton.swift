import SwiftUI

struct taskapeContinueButton: View {
    var body: some View {
        Text("continue").padding(20).frame(minWidth: 270)
            .font(.pathway(25))
            .background(
                RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
    }
}

#Preview {
    ZStack {
        taskapeContinueButton()
    }
}
