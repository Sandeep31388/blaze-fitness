import SwiftUI
import Observation

// Tracks progress within a single active workout session.
// All state is in-memory only — wiped when the user taps Exit.
@Observable
final class SessionModel {
    var completedVideoIDs: Set<String> = []
    var currentVideoID: String? = nil
    var isActive: Bool = false

    func startSession() {
        completedVideoIDs.removeAll()
        currentVideoID = nil
        isActive = true
    }

    func markCompleted(videoID: String) {
        completedVideoIDs.insert(videoID)
    }

    func isCompleted(videoID: String) -> Bool {
        completedVideoIDs.contains(videoID)
    }

    func progressFraction(totalVideos: Int) -> Double {
        guard totalVideos > 0 else { return 0 }
        return Double(completedVideoIDs.count) / Double(totalVideos)
    }

    // Called when user taps Exit — wipes all session state
    func endSession() {
        completedVideoIDs.removeAll()
        currentVideoID = nil
        isActive = false
    }
}
