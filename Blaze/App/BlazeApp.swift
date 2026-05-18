import SwiftUI

@main
struct BlazeApp: App {
    @State private var userModel = UserModel()
    @State private var workoutModel = WorkoutModel()
    @State private var sessionModel = SessionModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(userModel)
                .environment(workoutModel)
                .environment(sessionModel)
                .preferredColorScheme(.dark)
        }
    }
}
