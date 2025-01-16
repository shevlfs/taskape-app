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
        LottieView(animation: .named("anim"))
            .looping()
    }
}

#Preview {
    AuthenticationView()
}
