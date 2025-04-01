






import SwiftUI

struct EventCardBackGround: View {
    var friendColor: Color
    var size: EventSize

    private var proportions: (widthProportion: Double, heightProportion: Double)
    {
        switch size {
        case .small:
            return (0.32, 0.16)
        case .medium:
            return (0.56, 0.16)
        case .large:
            return (0.93, 0.16)
        }
    }
    var body: some View {
        MenuItem(
            mainColor: friendColor,
            widthProportion: proportions.widthProportion,
            heightProportion: proportions.heightProportion)
    }
}

#Preview {
    VStack(alignment: .center) {
        HStack(spacing: 20) {
            EventCardBackGround(friendColor: .blue, size: .small)
            EventCardBackGround(friendColor: .yellow, size: .medium)
        }
        EventCardBackGround(friendColor: .pink, size: .large)
    }
}
