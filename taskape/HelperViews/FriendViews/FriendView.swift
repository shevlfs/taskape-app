//
//  FriendView.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import SwiftUI

struct FriendView: View {
    var friendColor: Color
    var size: FriendCardSize

    private var proportions: (widthProportion: Double, heightProportion: Double)
    {
        switch size {
        case .small:
            return (0.32, 0.16)
        case .medium:
            return (0.56, 0.16)
        case .large:
            return (0.93, 0.16)
        }
    }
    var body: some View {
        MenuItem(
            mainColor: friendColor.opacity(0.6),
            widthProportion: proportions.widthProportion,
            heightProportion: proportions.heightProportion)
    }
}

#Preview {
    VStack(alignment: .center) {
        HStack(spacing: 20) {
            FriendView(friendColor: .blue, size: .small)
            FriendView(friendColor: .yellow, size: .medium)
        }
        FriendView(friendColor: .pink, size: .large)
    }
}
