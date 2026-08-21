import SwiftUI
import SwiftData

@main
struct GymProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Workout.self, Exercise.self, WorkoutSet.self])
    }
}
