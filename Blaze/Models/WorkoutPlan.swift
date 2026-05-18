import Foundation

// A single workout video item in the plan
struct WorkoutVideo: Identifiable, Codable, Equatable, Hashable {
    let id: String              // YouTube video ID
    let title: String
    let channelName: String
    let thumbnailURL: String
    let durationSeconds: Int
    let estimatedCalories: Int
    let activityType: ActivityType
    let proTip: String

    var youtubeURL: URL {
        URL(string: "https://www.youtube.com/embed/\(id)?playsinline=1&rel=0")!
    }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return s == 0 ? "\(m) min" : "\(m):\(String(format: "%02d", s)) min"
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case warmUp      = "Warm Up"
    case walking     = "Walking"
    case jogging     = "Jogging"
    case hiit        = "HIIT"
    case strength    = "Strength"
    case yoga        = "Yoga"
    case coolDown    = "Cool Down"
    case cycling     = "Cycling"
    case jumpRope    = "Jump Rope"
    case pilates     = "Pilates"

    var caloriesPerMinute: Double {
        switch self {
        case .warmUp:    return 3.0
        case .walking:   return 4.5
        case .jogging:   return 8.0
        case .hiit:      return 12.0
        case .strength:  return 6.0
        case .yoga:      return 3.5
        case .coolDown:  return 2.5
        case .cycling:   return 9.0
        case .jumpRope:  return 11.0
        case .pilates:   return 4.0
        }
    }
}

// A full workout plan containing an ordered list of videos
struct WorkoutPlan: Identifiable, Codable {
    let id: UUID
    var name: String
    let targetMinutes: Int
    let targetCalories: Int
    var videos: [WorkoutVideo]
    let createdAt: Date

    var totalDurationSeconds: Int { videos.reduce(0) { $0 + $1.durationSeconds } }
    var totalCalories: Int        { videos.reduce(0) { $0 + $1.estimatedCalories } }
    var totalMinutes: Int         { totalDurationSeconds / 60 }
}
