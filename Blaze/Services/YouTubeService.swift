import Foundation
import OSLog

// MARK: - YouTube Data API v3 response types

private struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]
}

private struct YouTubeSearchItem: Decodable {
    let id: YouTubeSearchItemID
    let snippet: YouTubeSnippet
}

private struct YouTubeSearchItemID: Decodable {
    let videoId: String?
}

private struct YouTubeSnippet: Decodable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

private struct YouTubeThumbnails: Decodable {
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
}

private struct YouTubeThumbnail: Decodable {
    let url: String
}

private struct YouTubeVideoListResponse: Decodable {
    let items: [YouTubeVideoDetail]
}

private struct YouTubeVideoDetail: Decodable {
    let id: String
    let contentDetails: YouTubeContentDetails
}

private struct YouTubeContentDetails: Decodable {
    let duration: String  // ISO 8601 e.g. "PT4M13S"
}

// MARK: - Service errors

enum YouTubeServiceError: LocalizedError {
    case missingAPIKey
    case noResults
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:         return "YouTube API key is not configured. Add it to BlazeConfig.swift."
        case .noResults:             return "No workout videos found. Try different time or calorie targets."
        case .networkError(let msg): return msg
        }
    }
}

// MARK: - Pro tips bank

private let proTips: [ActivityType: [String]] = [
    .warmUp:    ["A 5-minute warm-up raises your core temperature by ~1°C, reducing injury risk by up to 40%.",
                 "Dynamic stretches (leg swings, arm circles) are more effective pre-workout than static holds.",
                 "Drink 200–300ml of water before you start — even mild dehydration cuts performance by 5%."],
    .walking:   ["Walking at a 5–7% incline burns 50% more calories than flat walking at the same pace.",
                 "Swing your arms purposefully — it engages your core and adds ~10% to your calorie burn.",
                 "Aim for 100 steps per minute (brisk walk) to stay in the fat-burning zone."],
    .jogging:   ["Nasal breathing during easy jogging improves oxygen efficiency over time.",
                 "Land midfoot, not heel-first — reduces knee stress and improves running economy.",
                 "A 10-second sprint every 5 minutes during a jog raises total calorie burn by ~15%."],
    .hiit:      ["The 2:1 work-to-rest ratio (e.g. 40s on, 20s off) maximises the after-burn (EPOC) effect.",
                 "HIIT raises your resting metabolic rate for 24–48 hours after the session.",
                 "Keep rest periods honest — cutting them short before your heart rate drops defeats the purpose."],
    .strength:  ["Compound moves (squats, deadlifts, rows) burn 2× more calories than isolation exercises.",
                 "A 60-second rest between sets is enough to maintain strength while maximising calorie burn.",
                 "Muscle tissue burns 6–10 calories per pound per day at rest — more muscle = higher base burn."],
    .yoga:      ["Hold each pose 5 full breaths before moving — this activates the parasympathetic system and lowers cortisol.",
                 "Yoga lowers cortisol (the fat-storage hormone) by an average of 14% after a single session.",
                 "Flow yoga (Vinyasa) burns 140–180 calories in 30 minutes — comparable to a brisk walk."],
    .coolDown:  ["Static stretching post-workout improves flexibility by 8–10% over 4 weeks of consistent practice.",
                 "5 minutes of slow walking after high-intensity work removes lactic acid 3× faster than stopping abruptly.",
                 "Box breathing (4 counts in, 4 hold, 4 out, 4 hold) drops heart rate 20% faster than passive rest."],
    .cycling:   ["Cadence of 80–100 RPM (comfortable spinning) is more efficient than pushing hard at low RPM.",
                 "Cycling engages your glutes, quads, and hamstrings simultaneously — one of the highest-calorie activities per hour.",
                 "Standing on the pedals for 30-second bursts every few minutes raises intensity without higher perceived effort."],
    .jumpRope:  ["Jump rope burns ~11 calories per minute — more than most gym cardio machines.",
                 "Even 10 minutes of jump rope delivers cardiovascular benefits equivalent to 30 minutes of jogging.",
                 "Land softly on the balls of your feet, not flat-footed — protects ankles and improves timing."],
    .pilates:   ["Pilates activates the transverse abdominis (deep core) which most gym exercises miss entirely.",
                 "6 weeks of 3× weekly Pilates improves posture measurably and reduces lower-back pain in 80% of participants.",
                 "Combine Pilates with cardio on alternating days — the core strength translates directly to better running form."]
]

// MARK: - Search query variety pools
// Multiple distinct query strings per activity — each slot picks a different one
// so even two HIIT slots in the same plan return different videos.

private let searchQueries: [ActivityType: [String]] = [
    .warmUp:   ["full body warm up routine beginners",
                "dynamic warm up exercises before workout",
                "5 minute warm up stretching routine",
                "pre workout mobility warm up"],
    .walking:  ["indoor walking workout for weight loss",
                "walk at home cardio exercise",
                "brisk walking workout burn calories",
                "power walking cardio routine"],
    .jogging:  ["follow along jogging cardio workout",
                "indoor jog in place fat burning",
                "beginner jogging workout routine",
                "treadmill jogging pace workout"],
    .hiit:     ["high intensity interval training full body",
                "HIIT cardio fat burning workout",
                "tabata hiit workout no equipment",
                "intense hiit workout calorie burn",
                "hiit training home workout beginner"],
    .strength: ["full body strength training workout",
                "bodyweight strength exercises no equipment",
                "resistance training workout beginner",
                "muscle building strength routine home"],
    .yoga:     ["yoga flow for weight loss beginners",
                "vinyasa yoga fat burning session",
                "power yoga full body workout",
                "yoga cardio flow burn calories"],
    .coolDown: ["post workout cool down stretching",
                "full body cool down yoga stretch",
                "5 minute cool down after exercise",
                "recovery stretching routine post workout"],
    .cycling:  ["indoor cycling cardio workout",
                "stationary bike hiit workout",
                "cycling interval training cardio",
                "spin bike workout burn calories"],
    .jumpRope: ["jump rope workout for beginners",
                "jump rope hiit cardio routine",
                "skipping rope workout fat loss",
                "jump rope interval training cardio"],
    .pilates:  ["pilates core workout beginners",
                "pilates full body fat burning",
                "mat pilates workout tone body",
                "pilates cardio flow workout"]
]

// MARK: - YouTubeService

final class YouTubeService {
    static let shared = YouTubeService()
    private let log = Logger(subsystem: "com.blaze.app", category: "YouTubeService")

    private var apiKey: String { BlazeConfig.youtubeAPIKey }
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    // MARK: - Build a full workout plan

    func buildWorkoutPlan(targetMinutes: Int, targetCalories: Int) async throws -> WorkoutPlan {
        guard !apiKey.isEmpty else { throw YouTubeServiceError.missingAPIKey }

        let sequence = activitySequence(minutes: targetMinutes, calories: targetCalories)
        var videos: [WorkoutVideo] = []
        var usedVideoIDs = Set<String>()          // prevents duplicates across all slots
        var queryIndexPerActivity = [ActivityType: Int]()  // tracks which query variant to use next
        var remainingCalories = targetCalories
        var remainingSeconds  = targetMinutes * 60

        for activity in sequence {
            guard remainingSeconds > 30 else { break }

            let durationMinutes = min(activity.durationMinutes, remainingSeconds / 60)
            let estimatedCals   = Int(Double(durationMinutes) * activity.type.caloriesPerMinute)

            // Advance the query index for this activity type so repeated slots get different queries
            let queryIndex = queryIndexPerActivity[activity.type, default: 0]
            queryIndexPerActivity[activity.type] = queryIndex + 1

            if let video = try? await searchVideo(
                activity: activity.type,
                maxDurationSeconds: durationMinutes * 60,
                queryIndex: queryIndex,
                excluding: usedVideoIDs
            ) {
                usedVideoIDs.insert(video.id)
                let actualCals = Int(Double(video.durationSeconds / 60) * activity.type.caloriesPerMinute)
                videos.append(WorkoutVideo(
                    id:                video.id,
                    title:             video.title,
                    channelName:       video.channelName,
                    thumbnailURL:      video.thumbnailURL,
                    durationSeconds:   video.durationSeconds,
                    estimatedCalories: actualCals,
                    activityType:      activity.type,
                    proTip:            randomTip(for: activity.type)
                ))
                remainingSeconds  -= video.durationSeconds
                remainingCalories -= actualCals
            } else {
                let stub = stubVideo(activity: activity.type,
                                     durationSeconds: durationMinutes * 60,
                                     calories: estimatedCals)
                // Only add stub if its ID hasn't been used (multiple stubs would share the placeholder ID)
                if !usedVideoIDs.contains(stub.id) {
                    usedVideoIDs.insert(stub.id)
                    videos.append(stub)
                }
                remainingSeconds  -= durationMinutes * 60
                remainingCalories -= estimatedCals
            }

            if remainingCalories <= 0 { break }
        }

        guard !videos.isEmpty else { throw YouTubeServiceError.noResults }

        return WorkoutPlan(
            id:             UUID(),
            name:           "Blaze \(targetMinutes)-min Plan",
            targetMinutes:  targetMinutes,
            targetCalories: targetCalories,
            videos:         videos,
            createdAt:      Date()
        )
    }

    // MARK: - Activity sequencing

    private struct ActivitySlot {
        let type: ActivityType
        let durationMinutes: Int
    }

    private func activitySequence(minutes: Int, calories: Int) -> [ActivitySlot] {
        let calsPerMinute = Double(calories) / Double(minutes)
        let coreMinutes   = max(minutes - 10, 5)

        var slots: [ActivitySlot] = [.init(type: .warmUp, durationMinutes: 5)]

        if calsPerMinute >= 10 {
            slots += buildSlots(from: [.hiit, .jumpRope], totalMinutes: coreMinutes)
        } else if calsPerMinute >= 7 {
            slots += buildSlots(from: [.jogging, .cycling], totalMinutes: coreMinutes)
        } else if calsPerMinute >= 5 {
            slots += buildSlots(from: [.walking, .strength], totalMinutes: coreMinutes)
        } else {
            slots += buildSlots(from: [.yoga, .pilates], totalMinutes: coreMinutes)
        }

        slots.append(.init(type: .coolDown, durationMinutes: 5))
        return slots
    }

    private func buildSlots(from types: [ActivityType], totalMinutes: Int) -> [ActivitySlot] {
        let perActivity = max(totalMinutes / types.count, 5)
        return types.map { .init(type: $0, durationMinutes: perActivity) }
    }

    // MARK: - YouTube search

    private struct RawVideo {
        let id: String
        let title: String
        let channelName: String
        let thumbnailURL: String
        let durationSeconds: Int
    }

    private func searchVideo(
        activity: ActivityType,
        maxDurationSeconds: Int,
        queryIndex: Int,
        excluding usedIDs: Set<String>
    ) async throws -> RawVideo? {

        let pool    = searchQueries[activity] ?? ["\(activity.rawValue) workout"]
        let query   = pool[queryIndex % pool.count]
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Request 10 results per search so we have more candidates to pick a fresh one from
        let searchURLStr = "\(baseURL)/search?part=snippet&q=\(encoded)&type=video&videoDuration=medium&maxResults=10&key=\(apiKey)"
        guard let url = URL(string: searchURLStr) else { return nil }

        let (data, _)  = try await URLSession.shared.data(from: url)
        let response   = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

        let items = response.items.compactMap { item -> (String, String, String, String)? in
            guard let videoId = item.id.videoId,
                  !usedIDs.contains(videoId) else { return nil }   // skip already-used videos
            let thumb = item.snippet.thumbnails.high?.url
                     ?? item.snippet.thumbnails.medium?.url
                     ?? ""
            return (videoId, item.snippet.title, item.snippet.channelTitle, thumb)
        }

        guard !items.isEmpty else { return nil }

        // Fetch durations for all candidates in one API call
        let ids       = items.map { $0.0 }.joined(separator: ",")
        let detailURL = URL(string: "\(baseURL)/videos?part=contentDetails&id=\(ids)&key=\(apiKey)")!
        let (dData, _) = try await URLSession.shared.data(from: detailURL)
        let details    = try JSONDecoder().decode(YouTubeVideoListResponse.self, from: dData)

        // First pass: prefer a video that fits within the slot duration
        for (videoId, title, channel, thumb) in items {
            guard let detail = details.items.first(where: { $0.id == videoId }) else { continue }
            let secs = parseDuration(detail.contentDetails.duration)
            if secs <= maxDurationSeconds && secs > 60 {
                return RawVideo(id: videoId, title: title, channelName: channel,
                                thumbnailURL: thumb, durationSeconds: secs)
            }
        }

        // Second pass: accept the first unused result even if slightly over duration
        for (videoId, title, channel, thumb) in items {
            guard let detail = details.items.first(where: { $0.id == videoId }) else { continue }
            return RawVideo(id: videoId, title: title, channelName: channel,
                            thumbnailURL: thumb,
                            durationSeconds: parseDuration(detail.contentDetails.duration))
        }

        return nil
    }

    // MARK: - ISO 8601 duration parser (PT4M13S → seconds)

    private func parseDuration(_ iso: String) -> Int {
        var seconds = 0
        var current = ""
        for char in iso {
            if char.isNumber { current.append(char) }
            else if char == "H" { seconds += (Int(current) ?? 0) * 3600; current = "" }
            else if char == "M" { seconds += (Int(current) ?? 0) * 60;   current = "" }
            else if char == "S" { seconds += Int(current) ?? 0;          current = "" }
        }
        return seconds
    }

    // MARK: - Pro tip helper

    private func randomTip(for activity: ActivityType) -> String {
        let tips = proTips[activity] ?? ["Stay consistent — results compound over time."]
        return tips.randomElement() ?? tips[0]
    }

    // MARK: - Fetch a replacement for a blocked video

    func fetchReplacement(
        for activity: ActivityType,
        durationSeconds: Int,
        excluding usedIDs: Set<String>
    ) async throws -> WorkoutVideo? {
        let pool = searchQueries[activity] ?? ["\(activity.rawValue) workout"]
        // Try each query in the pool until we find a working video not already in the plan
        for query in pool {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let searchURLStr = "\(baseURL)/search?part=snippet&q=\(encoded)&type=video&videoDuration=medium&maxResults=10&key=\(apiKey)"
            guard let url = URL(string: searchURLStr) else { continue }

            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let response  = try? JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            else { continue }

            let items = response.items.compactMap { item -> (String, String, String, String)? in
                guard let videoId = item.id.videoId,
                      !usedIDs.contains(videoId) else { return nil }
                let thumb = item.snippet.thumbnails.high?.url
                         ?? item.snippet.thumbnails.medium?.url ?? ""
                return (videoId, item.snippet.title, item.snippet.channelTitle, thumb)
            }
            guard !items.isEmpty else { continue }

            let ids = items.map { $0.0 }.joined(separator: ",")
            guard let detailURL = URL(string: "\(baseURL)/videos?part=contentDetails&id=\(ids)&key=\(apiKey)"),
                  let (dData, _) = try? await URLSession.shared.data(from: detailURL),
                  let details    = try? JSONDecoder().decode(YouTubeVideoListResponse.self, from: dData)
            else { continue }

            for (videoId, title, channel, thumb) in items {
                guard let detail = details.items.first(where: { $0.id == videoId }) else { continue }
                let secs = parseDuration(detail.contentDetails.duration)
                guard secs > 60 else { continue }
                return WorkoutVideo(
                    id:                videoId,
                    title:             title,
                    channelName:       channel,
                    thumbnailURL:      thumb,
                    durationSeconds:   secs,
                    estimatedCalories: Int(Double(secs / 60) * activity.caloriesPerMinute),
                    activityType:      activity,
                    proTip:            randomTip(for: activity)
                )
            }
        }
        return nil
    }

    // MARK: - Stub video (fallback when API returns nothing)

    private func stubVideo(activity: ActivityType, durationSeconds: Int, calories: Int) -> WorkoutVideo {
        WorkoutVideo(
            id:                UUID().uuidString,   // unique ID so stubs never collide with each other
            title:             "\(activity.rawValue) — \(durationSeconds / 60) min session",
            channelName:       "Blaze Fitness",
            thumbnailURL:      "",
            durationSeconds:   durationSeconds,
            estimatedCalories: calories,
            activityType:      activity,
            proTip:            randomTip(for: activity)
        )
    }
}
