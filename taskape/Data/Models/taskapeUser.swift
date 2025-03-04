//
//  TaskapeUser.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class taskapeUser {
    var id: String
    var handle: String
    var bio: String
    var profileImageURL: String
    var profileColor: String
    @Relationship var tasks: [taskapeTask]

    init(
        id: String = UUID().uuidString,
        handle: String,
        bio: String,
        profileImage: String,
        profileColor: String
    ) {
        self.id = id
        self.handle = handle
        self.bio = bio
        self.profileImageURL = profileImage
        self.profileColor = profileColor
        self.tasks = []
    }
}
