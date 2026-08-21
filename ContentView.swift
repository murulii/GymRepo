import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            DashboardView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            WorkoutView().tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }.tag(1)
            HistoryView().tabItem { Label("History", systemImage: "clock.arrow.circlepath") }.tag(2)
            ProgressView().tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }.tag(3)
        }
        .tint(.green)
    }
}

struct DashboardView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var recent: Workout? { workouts.first }
    var totalVolume: Double {
        workouts.flatMap(\.sets).reduce(0) { $0 + $1.volume }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Good morning 👋")
                        .font(.title2.bold())
                    Text("Ready to crush your goals?")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Today's Workout", systemImage: "figure.strengthtraining.traditional")
                            .foregroundStyle(.green)
                        Text(recent?.name ?? "Upper A")
                            .font(.title.bold())
                        Text("Track every set, rep and PR.")
                            .foregroundStyle(.secondary)
                        NavigationLink("Start Workout") {
                            WorkoutView()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding()
                    .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))

                    HStack {
                        StatCard(title: "Workouts", value: "\(workouts.count)")
                        StatCard(title: "Volume", value: "\(Int(totalVolume)) kg")
                    }

                    Text("Recent PRs").font(.title3.bold())
                    if let workout = recent, !workout.sets.isEmpty {
                        ForEach(workout.sets.prefix(5)) { set in
                            HStack {
                                Text(set.exerciseName)
                                Spacer()
                                Text("\(set.weight.clean) kg × \(set.reps)")
                                    .bold()
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Text("No workouts yet. Start your first session!")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("GYM PRO")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).foregroundStyle(.secondary)
            Text(value).font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var exercise = "Incline Dumbbell Press"
    @State private var weight = 25.0
    @State private var reps = 10
    @State private var rpe = 8
    @State private var rest = 90
    @State private var timer: Timer?
    @State private var remaining = 0
    @State private var currentWorkout: Workout?

    let exercises = [
        "Incline Dumbbell Press", "Dumbbell Row", "Lat Pulldown",
        "Overhead Shoulder Press", "Cable Fly", "Biceps Curl", "Leg Press", "Squat"
    ]

    var previous: WorkoutSet? {
        workouts.dropFirst().flatMap(\.sets).last(where: { $0.exerciseName == exercise })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Picker("Exercise", selection: $exercise) {
                        ForEach(exercises, id: \.self) { Text($0) }
                    }
                }

                if let previous {
                    Section("Last time") {
                        HStack {
                            Text("\(previous.weight.clean) kg × \(previous.reps)")
                            Spacer()
                            Text("Today target: \(suggestedWeight.clean) kg × \(suggestedReps)")
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section("Log Set") {
                    Stepper("Weight: \(weight.clean) kg", value: $weight, in: 0...300, step: 2.5)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                    Stepper("RPE: \(rpe)", value: $rpe, in: 1...10)

                    Button("Add Set") { addSet() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }

                Section("Rest Timer") {
                    Text(remaining > 0 ? "\(remaining / 60):\(String(format: "%02d", remaining % 60))" : "Ready")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    HStack {
                        Button("Start 60s") { startTimer(60) }
                        Button("Start 90s") { startTimer(90) }
                        Button("Stop") { stopTimer() }
                    }
                }

                Section("Today") {
                    if let currentWorkout {
                        ForEach(currentWorkout.sets.filter { $0.exerciseName == exercise }) { set in
                            HStack {
                                Text("Set \(set.setNumber)")
                                Spacer()
                                Text("\(set.weight.clean) kg × \(set.reps)")
                            }
                        }
                    } else {
                        Text("No sets logged yet.")
                            .foregroundStyle(.secondary)
                    }
                }

                if let previous {
                    Section("Comparison") {
                        let delta = reps - previous.reps
                        Text(delta > 0 ? "🔥 +\(delta) reps vs last time" :
                             delta < 0 ? "⚠️ \(delta) reps vs last time" :
                             "Same reps as last time")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Workout")
            .onAppear {
                if currentWorkout == nil {
                    currentWorkout = Workout(name: "Upper A")
                    context.insert(currentWorkout!)
                }
            }
            .onDisappear { stopTimer() }
        }
    }

    var suggestedWeight: Double {
        guard let p = previous else { return weight }
        return p.reps >= 10 ? p.weight + 2.5 : p.weight
    }

    var suggestedReps: Int {
        guard let p = previous else { return reps }
        return min(15, p.reps + 1)
    }

    func addSet() {
        guard let workout = currentWorkout else { return }
        let next = workout.sets.filter { $0.exerciseName == exercise }.count + 1
        workout.sets.append(WorkoutSet(exerciseName: exercise, setNumber: next,
                                       weight: weight, reps: reps, rpe: rpe, workout: workout))
        try? context.save()
    }

    func startTimer(_ seconds: Int) {
        stopTimer()
        remaining = seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 { remaining -= 1 } else { stopTimer() }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    Section {
                        ForEach(workout.sets) { set in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(set.exerciseName).bold()
                                    Text("Set \(set.setNumber) • RPE \(set.rpe)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(set.weight.clean) kg × \(set.reps)")
                            }
                        }
                    } header: {
                        Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct ProgressView: View {
    @Query private var workouts: [Workout]

    var volume: Double {
        workouts.flatMap(\.sets).reduce(0) { $0 + $1.volume }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Progress").font(.largeTitle.bold())

                    HStack {
                        StatCard(title: "Total Volume", value: "\(Int(volume)) kg")
                        StatCard(title: "Sessions", value: "\(workouts.count)")
                    }

                    Text("Training Insights").font(.title3.bold())
                    InsightRow(icon: "chart.line.uptrend.xyaxis", text: "Track weight and reps every session.")
                    InsightRow(icon: "trophy.fill", text: "Personal records are preserved automatically.")
                    InsightRow(icon: "arrow.up.right", text: "Smart targets increase when your reps improve.")
                    InsightRow(icon: "clock.fill", text: "Use the rest timer between sets.")
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.green).frame(width: 28)
            Text(text)
            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
