//
//  MenuItem.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import SwiftUI

struct MenuItem: View {
    var mainColor: Color
    var widthProportion: CGFloat
    var heightProportion: CGFloat

    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(
                 width: UIScreen.main.bounds.width * widthProportion,
                height: UIScreen.main.bounds.height * heightProportion
            )
            .background(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: mainColor, location: 0.06),
                        Gradient.Stop(
                            color: mainColor.opacity(0.6), location: 0.31
                        ),
                        Gradient.Stop(color: mainColor.opacity(0.25), location: 0.81),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 1),
                    endPoint: UnitPoint(x: 0.5, y: 0)
                )
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 0.5)
                    .stroke(mainColor.opacity(0.15), lineWidth: 1)
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
