import Foundation
import SwiftData

@Model
final class Workout {
    var date: Date
    var name: String
    var duration: Int
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []

    init(name: String, date: Date = .now, duration: Int = 0) {
        self.name = name
        self.date = date
        self.duration = duration
    }
}

@Model
final class Exercise {
    var name: String
    var muscle: String

    init(name: String, muscle: String) {
        self.name = name
        self.muscle = muscle
    }
}

@Model
final class WorkoutSet {
    var exerciseName: String
    var setNumber: Int
    var weight: Double
    var reps: Int
    var rpe: Int
    var workout: Workout?

    init(exerciseName: String, setNumber: Int, weight: Double, reps: Int, rpe: Int = 8, workout: Workout? = nil) {
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.workout = workout
    }

    var volume: Double { weight * Double(reps) }
}
