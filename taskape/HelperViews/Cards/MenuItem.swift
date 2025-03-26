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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(
                width: UIScreen.main.bounds.width * widthProportion,
                height: UIScreen.main.bounds.height * heightProportion
            )
            .background(
                LinearGradient(
                    stops: colorScheme == .dark
                        ? [
                            // Enhanced gradient stops for dark mode
                            Gradient.Stop(
                                color: mainColor.opacity(0.95), location: 0.05),
                            Gradient.Stop(
                                color: mainColor.opacity(0.75), location: 0.4),
                            Gradient.Stop(
                                color: mainColor.opacity(0.5), location: 0.8),
                        ]
                        : [
                            // Original gradient stops for light mode
                            Gradient.Stop(color: mainColor, location: 0.06),
                            Gradient.Stop(
                                color: mainColor.opacity(0.6), location: 0.31),
                            Gradient.Stop(
                                color: mainColor.opacity(0.25), location: 0.81),
                        ],
                    startPoint: UnitPoint(x: 0.5, y: 1),
                    endPoint: UnitPoint(x: 0.5, y: 0)
                )
            )

            .glow(color: mainColor.opacity(0.15), radius: 2).blur(radius: 0.5, opaque: false)

            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 0.5)
                    .stroke(
                        colorScheme == .dark
                            ? mainColor.opacity(0.4) : mainColor.opacity(0.15),
                        lineWidth: colorScheme == .dark ? 1.5 : 1
                    )
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

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}
