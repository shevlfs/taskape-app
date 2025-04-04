import SwiftData
import SwiftUI

@main
struct taskapeApp: App {
    @StateObject private var appState = AppStateManager()
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(ModelContainer.shared)
                .environmentObject(appState).onAppear {
                    let memoryCapacity = 50 * 1024 * 1024 * 2
                    let diskCapacity = 200 * 1024 * 1024 * 5

                    URLCache.shared.memoryCapacity = memoryCapacity
                    URLCache.shared.diskCapacity = diskCapacity
                }
        }
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(
                for: taskapeUser.self, taskapeTask.self, taskapeEvent.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
