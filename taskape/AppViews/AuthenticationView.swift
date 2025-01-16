//
//  AuthenticationView.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Lottie
import SwiftUI

struct AuthenticationView: View {
    @State private var isPlaying: Bool = true

    var body: some View {
        ZStack {
            LottieView(animation: .named("taskapescreensmall"))

                .looping().scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Button(action: {}){
                    LandingButton()
                }.buttonStyle(.plain).padding(.bottom, 130)
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
