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
    @StateObject private var appState = AppStateManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(ModelContainer.shared)
                .environmentObject(appState)
        }
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: taskapeUser.self, taskapeTask.self, taskapeEvent.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
