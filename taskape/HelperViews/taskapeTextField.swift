//
//  taskapeTextField.swift
//  taskape
//
//  Created by shevlfs on 1/17/25.
//

import SwiftUI

struct taskapeTextField: View {
    @State private var current_string: String = ""
    @State var placeholder: String = ""

    var body: some View {
        TextField(
            placeholder,
            text: $current_string
        ).accentColor(.taskapeOrange).autocorrectionDisabled()
            .autocapitalization(.none).multilineTextAlignment(.center).padding(
                .horizontal, 15
            ).padding(.vertical, 15).frame(maxWidth: 270).font(
                .pathwayBlack(20)
            ).background(
                RoundedRectangle(cornerRadius: 30).fill(.regularMaterial)
                    .stroke(.thinMaterial, style: StrokeStyle(lineWidth: 1))
            )
    }
}

#Preview {
    taskapeTextField()
}
