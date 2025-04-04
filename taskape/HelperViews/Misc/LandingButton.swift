import SwiftUI

struct LandingButton: View {
    var body: some View {
        Text("feeling productive?").padding(20)
            .font(.pathway(25))
            .background(Rectangle().fill(.ultraThinMaterial)).cornerRadius(30)
    }
}

#Preview {
    LandingButton()
}
