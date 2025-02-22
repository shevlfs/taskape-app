//
//  Item.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import Foundation
import SwiftData
import SwiftUICore

@Model
final class taskapeTask: Identifiable {
    var id: String
    var name: String
    var taskDescription: String
    var author: String
    var createdAt: Date
    var isCompleted: Bool
    var privacy: String
    var deadline: Date?

    init(
        id: String = UUID().uuidString, name: String, taskDescription: String,
        author: String, privacy: String
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.author = author
        self.createdAt = Date()
        self.isCompleted = false
        self.privacy = privacy
    }
}
