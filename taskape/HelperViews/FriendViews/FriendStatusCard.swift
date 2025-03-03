//
//  FriendStatusCard.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import SwiftUI

enum FriendCardSize {
    case small
    case medium
    case large
}

enum eventType: String, Codable {
    case newTasks
    case completedTasks
    case newUser
}

struct FriendStatusCard: View {
    var friend: taskapeUser
    var friendCardSize: FriendCardSize
    var taskArray: [taskapeTask] = []
    var body: some View {
        switch friendCardSize {
        case .small:
            FriendView(
                friendColor: Color(hex: friend.profileColor), size: .small)
        case .medium:
            FriendView(
                friendColor: Color(hex: friend.profileColor),
                size: .medium
            )
        case .large:
            FriendView(
                friendColor: Color(hex: friend.profileColor), size: .large)
        }
    }
}

#Preview {
    FriendStatusCard(
        friend: taskapeUser(
            id: "asda",
            handle: "john pork",
            bio: "john is called john",
            profileImage: "",
            profileColor: "000FFF"
        ),
        friendCardSize: .small
    )
}
