import SwiftUI

struct TaskapeColor: Identifiable, Hashable {
    let id = UUID()
    let color: Color
    let hex: String

    static let presetColors: [TaskapeColor] = [
        TaskapeColor(color: Color(hex: "#FF6B6B"), hex: "#FF6B6B"),
        TaskapeColor(color: Color(hex: "#FF9F43"), hex: "#FF9F43"),
        TaskapeColor(color: Color(hex: "#FECA57"), hex: "#FECA57"),
        TaskapeColor(color: Color(hex: "#4CD97B"), hex: "#4CD97B"),
        TaskapeColor(color: Color(hex: "#2E86DE"), hex: "#2E86DE"),
        TaskapeColor(color: Color(hex: "#9B5DE5"), hex: "#9B5DE5"),
        TaskapeColor(color: Color(hex: "#F15BB5"), hex: "#F15BB5"),
        TaskapeColor(color: Color(hex: "#FF8B94"), hex: "#FF8B94"),
        TaskapeColor(color: Color(hex: "#4ECDC4"), hex: "#4ECDC4"),
        TaskapeColor(color: Color(hex: "#45B7D1"), hex: "#45B7D1"),
        TaskapeColor(color: Color(hex: "#96CEB4"), hex: "#96CEB4"),
        TaskapeColor(color: Color(hex: "#FFCC5C"), hex: "#FFCC5C"),
        TaskapeColor(color: Color(hex: "#FF9AA2"), hex: "#FF9AA2"),
        TaskapeColor(color: Color(hex: "#B39CD0"), hex: "#B39CD0"),
    ]
}

extension Color {
    static var taskapeOrange: Color {
        Color(red: 0.914, green: 0.427, blue: 0.078)
    }
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (
                int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = cgColor?.components else { return "#000000" }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension View {
    func percentageOffset(x: Double = 0, y: Double = 0) -> some View {
        self
            .modifier(PercentageOffset(x: x, y: y))
    }
}

struct PercentageOffset: ViewModifier {

    let x: Double
    let y: Double

    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {

        content
            .background(
                GeometryReader { geo in Color.clear.onAppear { size = geo.size }
                }
            )
            .offset(x: size.width * x, y: size.height * y)
    }
}
