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
    var profileImageData: Data?
    var profileColor: String

    init(
        id: String,
        handle: String,
        bio: String,
        profileImage: UIImage? = nil,
        profileColor: String
    ) {
        self.id = id
        self.handle = handle
        self.bio = bio
        self.profileImageData = profileImage?.jpegData(compressionQuality: 0.8)
        self.profileColor = profileColor
    }
}
