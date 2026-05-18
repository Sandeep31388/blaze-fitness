import SwiftUI

struct RootView: View {
    @Environment(UserModel.self) private var userModel

    var body: some View {
        Group {
            if userModel.isAuthenticated {
                HomeView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userModel.isAuthenticated)
    }
}
