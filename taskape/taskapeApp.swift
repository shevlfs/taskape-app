//
//  taskapeApp.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import SwiftData
import SwiftUI

@main
struct taskapeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for:
                    taskapeUser.self, taskapeTask.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView().modelContainer(container)
        }
    }
}
