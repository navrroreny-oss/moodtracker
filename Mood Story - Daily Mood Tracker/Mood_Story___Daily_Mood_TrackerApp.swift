import SwiftUI
import SwiftData

@main
struct MoodStoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: MoodEntry.self)
        }
    }
}
