import SwiftUI

struct TaskapeLogo: View {
    var body: some View {
        HStack {
            Text("task").font(.pathwayRegular).offset(x: 6)
            Text("ape")
                .font(.pathwayBlack)
                .foregroundColor(Color.taskapeOrange)
        }
    }
}

#Preview {
    TaskapeLogo()
}
