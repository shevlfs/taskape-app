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

enum event{
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
            FriendView(friendColor: colorFromString(friend.profileColor), size: .small)
        case .medium:
            FriendView(
                friendColor:colorFromString(friend.profileColor) ,
                size: .medium
            )
        case .large:
            FriendView(friendColor: colorFromString(friend.profileColor), size: .large)
        }
    }
}

#Preview {
    FriendStatusCard(
        friend: taskapeUser(
            id: UUID(),
            name: "john pork",
            bio: "john is called john",
            profileImage: nil,
            profileColor: "blue"
        ),
        friendCardSize: .small
    )
}
