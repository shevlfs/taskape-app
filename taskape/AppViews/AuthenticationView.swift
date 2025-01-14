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
    @State private 


    var body: some View {
        Button(action: {}){
            LandingButton()
        }.buttonStyle(.plain)
    }
}

#Preview {
    AuthenticationView()
}
