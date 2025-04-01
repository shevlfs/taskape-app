






import SwiftUI

struct MenuItem: View {
    var mainColor: Color
    var widthProportion: CGFloat
    var heightProportion: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear).frame(
                    width: UIScreen.main.bounds.width * widthProportion,
                    height: UIScreen.main.bounds.height * heightProportion
                )
                .background(
                    LinearGradient(
                        stops: colorScheme == .dark
                            ? [

                                Gradient.Stop(
                                    color: mainColor.opacity(0.95),
                                    location: 0.05),
                                Gradient.Stop(
                                    color: mainColor.opacity(0.75),
                                    location: 0.4),
                                Gradient.Stop(
                                    color: mainColor.opacity(0.5), location: 0.8
                                ),
                            ]
                            : [

                                Gradient.Stop(color: mainColor, location: 0.06),
                                Gradient.Stop(
                                    color: mainColor.opacity(0.6),
                                    location: 0.31),
                                Gradient.Stop(
                                    color: mainColor.opacity(0.25),
                                    location: 0.81),
                            ],
                        startPoint: UnitPoint(x: 0.5, y: 1),
                        endPoint: UnitPoint(x: 0.5, y: 0)
                    ).clipShape(RoundedRectangle(cornerRadius: 20))
                )


        } .overlay(
            RoundedRectangle(cornerRadius: 30)

                .stroke(
                    colorScheme == .dark
                        ? mainColor.opacity(0.3)
                        : mainColor.opacity(0.3),
                    lineWidth: colorScheme == .dark ? 1 : 1
                ).blur(radius: 3)
        )
    }
}

#Preview {
    MenuItem(
        mainColor: .pink,
        widthProportion: 0.5,
        heightProportion: 0.5
    )
}

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

struct VisionProShadowStyle {
    let primary: Shadow
    let secondary: Shadow
    let tertiary: Shadow?
    let backgroundBlur: CGFloat

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: CGFloat
    }


    static let floatingCard = VisionProShadowStyle(
        primary: Shadow(
            color: .black,
            radius: 16,
            x: 0,
            y: 4,
            opacity: 0.1
        ),
        secondary: Shadow(
            color: .black,
            radius: 30,
            x: 0,
            y: 12,
            opacity: 0.08
        ),
        tertiary: Shadow(
            color: .white,
            radius: 3,
            x: 0,
            y: -1,
            opacity: 0.1
        ),
        backgroundBlur: 0.3
    )


    static let button = VisionProShadowStyle(
        primary: Shadow(
            color: .black,
            radius: 10,
            x: 0,
            y: 2,
            opacity: 0.12
        ),
        secondary: Shadow(
            color: .black,
            radius: 16,
            x: 0,
            y: 5,
            opacity: 0.05
        ),
        tertiary: nil,
        backgroundBlur: 0.15
    )


    static let text = VisionProShadowStyle(
        primary: Shadow(
            color: .black,
            radius: 5,
            x: 0,
            y: 1,
            opacity: 0.12
        ),
        secondary: Shadow(
            color: .black,
            radius: 10,
            x: 0,
            y: 3,
            opacity: 0.05
        ),
        tertiary: nil,
        backgroundBlur: 0
    )
}


extension View {
    @ViewBuilder
    func visionProShadow(style: VisionProShadowStyle = .floatingCard)
        -> some View
    {
        self
            .shadow(
                color: style.primary.color.opacity(style.primary.opacity),
                radius: style.primary.radius,
                x: style.primary.x,
                y: style.primary.y
            )
            .shadow(
                color: style.secondary.color.opacity(style.secondary.opacity),
                radius: style.secondary.radius,
                x: style.secondary.x,
                y: style.secondary.y
            )
            .overlay(
                style.tertiary.map { tertiary in
                    Color.clear
                        .shadow(
                            color: tertiary.color.opacity(tertiary.opacity),
                            radius: tertiary.radius,
                            x: tertiary.x,
                            y: tertiary.y
                        )
                        .allowsHitTesting(false)
                }
            )
            .background(
                BlurEffect(style: .systemUltraThinMaterial)
                    .opacity(style.backgroundBlur)
                    .allowsHitTesting(false)
            )
    }


    func visionProFloatingCard(
        cornerRadius: CGFloat = 16,
        backgroundOpacity: CGFloat = 0.5,
        backgroundBlur: CGFloat = 0.7
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        BlurEffect(style: .systemThinMaterial)
                            .opacity(backgroundBlur)
                    )
                    .opacity(backgroundOpacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .visionProShadow(style: .floatingCard)
    }
}

struct BlurEffect: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
