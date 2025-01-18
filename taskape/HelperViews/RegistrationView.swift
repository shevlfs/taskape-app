//
//  RegistrationView.swift
//  taskape
//
//  Created by shevlfs on 1/17/25.
//

import SwiftUI

struct RegistrationView: View {
    var body: some View {
        VStack {
            Text("heyyy, so, uh... \n what's your number?").multilineTextAlignment(.center)
                .font(.pathway(26))
                .padding(.top, 130)

            taskapeTextField().padding(.top, 80)
            Spacer()
        }
    }
}

#Preview {
    RegistrationView()
}
