//
//  AuthenticationView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Lottie
import SwiftUI

struct AuthenticationView: View {
    @Environment(\.colorScheme) var colorScheme

    @State var LandingButtonPressed = false

    var body: some View {
        ZStack {
            LottieView(
                animation: .named(
                    colorScheme == .dark ? "taskapeblack" : "taskapewhite")
            )

            .looping().scaledToFill()
            .edgesIgnoringSafeArea(.all).opacity(LandingButtonPressed ? 0.6 : 1)
            .blur(
                radius:
                    LandingButtonPressed ? 15 : 0
            ).animation(
                .bouncy(
                    duration: 1.5
                ),
                value: LandingButtonPressed
            )

            VStack {
                Spacer()
                Button(action: {
                    LandingButtonPressed = true
                }) {
                    LandingButton()
                }.buttonStyle(.plain).padding(.bottom, 130)
            }.opacity(LandingButtonPressed ? 0 : 1).blur(
                radius:
                    LandingButtonPressed ? 10 : 0
            ).animation(.bouncy(duration: 1), value: LandingButtonPressed)

            RegistrationView()
                .opacity(LandingButtonPressed ? 1 : 0)
                .animation(.bouncy(duration: 3), value: LandingButtonPressed)
                .disabled(
                    !LandingButtonPressed
                )
        }
    }
}

#Preview {
    AuthenticationView()
}
