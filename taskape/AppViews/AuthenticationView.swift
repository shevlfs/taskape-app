//
//  AuthenticationView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Lottie
import SwiftUI

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

struct AuthenticationView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var LandingButtonPressed = false
    var body: some View {
        ScrollView {
            ZStack {
                Button(action: {
                    LandingButtonPressed = true
                }) {
                    LandingButton()
                }.sensoryFeedback(.success, trigger: LandingButtonPressed)
                    .buttonStyle(.plain)
                    .opacity(LandingButtonPressed ? 0 : 1).blur(
                        radius:
                            LandingButtonPressed ? 10 : 0
                    ).animation(
                        .snappy(duration: 1.0), value: LandingButtonPressed).percentageOffset(y: 2.8)

                RegistrationView()
                    .opacity(LandingButtonPressed ? 1 : 0)
                    .animation(
                        .snappy(duration: 1.0), value: LandingButtonPressed
                    )
                    .disabled(
                        !LandingButtonPressed
                    )
            }
        }.scrollDisabled(true).background(
            LottieView(
                animation: .named(
                    colorScheme == .dark ? "taskapeblack" : "taskapewhite")
            ).configuration(
                LottieConfiguration(
                    renderingEngine: .automatic
                )
            ).looping().backgroundBehavior(.pauseAndRestore).animationSpeed(
                LandingButtonPressed ? 0.4 : 1
            ).scaledToFill()
                .edgesIgnoringSafeArea(.all).opacity(
                    LandingButtonPressed ? 0.5 : 1
                )
                .blur(
                    radius:
                        LandingButtonPressed ? 15 : 0
                ).animation(
                    .snappy(
                        duration: 1.0
                    ),
                    value: LandingButtonPressed
                )
        )
    }
}

#Preview {
    AuthenticationView()
}
