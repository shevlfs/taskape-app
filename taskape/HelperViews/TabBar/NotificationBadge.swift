






import SwiftUI

struct NotificationBadge: View {
    @Binding var badgeCount: Int
    @State var foreground: Color = .white
    @State var background: Color = .red

    private let size = 16.0

    var body: some View {
        ZStack {
            Capsule()
                .fill(background)
                .frame(
                    width: size * widthMultplier(),
                    height: size,
                    alignment: .center
                )

            if hasTwoOrLessDigits() {
                Text("\(badgeCount)")
                    .foregroundColor(foreground)
                    .font(.pathwayBoldCondensed)
                    .minimumScaleFactor(0.5)
            } else {
                Text("99+")
                    .foregroundColor(foreground)
                    .font(.pathwayBoldCondensed)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size * widthMultplier(), height: size)
        .opacity(badgeCount == 0 ? 0 : 1)
    }

    func hasTwoOrLessDigits() -> Bool {
        return badgeCount < 100
    }

    func widthMultplier() -> Double {
        if badgeCount < 10 {
            return 1.0
        } else if badgeCount < 100 {
            return 1.5
        } else {
            return 2.0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Preview")
            .overlay(
                NotificationBadge(badgeCount: .constant(5))
                    .offset(x: 10, y: -10),
                alignment: .topTrailing
            )
    }
}
