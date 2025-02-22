//
//  taskapeStatus.swift
//  taskape
//
//  Created by shevlfs on 1/7/25.
//

import Foundation
import SwiftData
import SwiftUI

final class taskapeStatus: ObservableObject {
    var userID: String
    var userHandle: String
    var type: eventType
    var tasks: [taskapeTask]

    init(user: taskapeUser, type: eventType, tasks: [taskapeTask]) {
        self.userID = user.id
        self.userHandle = user.handle
        self.type = type
        self.tasks = tasks
    }
}
