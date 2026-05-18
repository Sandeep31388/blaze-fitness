import SwiftUI
import Observation

@Observable
final class UserModel {
    var isAuthenticated: Bool = false
    var displayName: String = ""
    var email: String = ""

    // Persisted via AppStorage equivalents — restored on init
    @ObservationIgnored @AppStorage("blaze_display_name") private var storedName: String = ""
    @ObservationIgnored @AppStorage("blaze_email")        private var storedEmail: String = ""
    @ObservationIgnored @AppStorage("blaze_authed")       private var storedAuthed: Bool = false

    init() {
        displayName     = storedName
        email           = storedEmail
        isAuthenticated = storedAuthed
    }

    func signIn(email: String, name: String) {
        self.email          = email
        self.displayName    = name
        self.isAuthenticated = true
        storedEmail         = email
        storedName          = name
        storedAuthed        = true
    }

    func signOut() {
        isAuthenticated = false
        storedAuthed    = false
    }
}
