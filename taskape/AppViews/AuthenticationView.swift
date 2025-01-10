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
        VStack {
            Text("Authentication")
            LottieView(animation: .named("taskape_landing"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 200)
        }
    }
}

#Preview {
    AuthenticationView()
}
