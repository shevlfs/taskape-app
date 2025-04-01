//
//  taskapeGroup.swift
//  taskape
//
//  Created by shevlfs on 3/27/25.
//

import SwiftData

@Model
final class taskapeGroup {
    var id: String
    var userids: [String]
    var group_name: String
    var group_description: String
    var admins: [String] = []

    init(
        id: String, userids: [String], group_name: String,
        group_description: String, admins: [String]
    ) {
        self.id = id
        self.userids = userids
        self.group_name = group_name
        self.group_description = group_description
        self.admins = admins
    }
}
