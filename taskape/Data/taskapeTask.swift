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
final class taskapeTask {
    var id: UUID = UUID()
    var name: String
    var taskDescription: String
    var author: String
    var createdAt: Date
    var isCompleted: Bool

    init(name: String, taskDescription: String, author: String) {
        self.name = name
        self.taskDescription = taskDescription
        self.author = author
        self.createdAt = Date()
        self.isCompleted = false
    }
}

func colorFromString(_ string: String) -> Color {
    switch string {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "yellow": return .yellow
    case "purple": return .purple
    case "pink": return .pink
    default: return .gray

    }
}
