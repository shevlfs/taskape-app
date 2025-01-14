//
//  LandingButton.swift
//  taskape
//
//  Created by shevlfs on 1/12/25.
//

import SwiftUI

struct LandingButton: View {
    var body: some View {
        Text("feeling productive?").padding()
                .font(.pathwayRegular)
                .background(Rectangle().fill(.ultraThinMaterial)).cornerRadius(30)
    }
}

#Preview {
    LandingButton()
}
