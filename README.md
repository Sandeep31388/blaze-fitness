# Blaze — iOS Workout Planner

_Last updated: 18 May 2026_

Blaze is an iOS app that builds a personalised workout plan and curates a YouTube video playlist based on the time and calories a user wants to burn.

---

## What it does

1. Creates a user account (email or Apple Sign-In)
2. Takes two inputs: how many minutes to exercise and how many calories to burn
3. Generates a step-by-step workout plan (warm-up → activity → cool-down)
4. Searches YouTube and builds a video playlist that fits within the time and calorie targets
5. Plays YouTube videos inline inside the app via WKWebView
6. Tracks progress with a pie chart; an Exit button clears the session
7. Shows a pro tip under each video covering fat loss, stamina, and diet

---

## Project structure

```
Blaze/
├── Blaze/
│   ├── App/
│   │   ├── BlazeApp.swift          — App entry point, model injection
│   │   └── RootView.swift          — Auth gate (Welcome vs Home)
│   ├── Models/
│   │   ├── UserModel.swift         — Auth state, AppStorage persistence
│   │   ├── WorkoutModel.swift      — Plan generation, saved plans
│   │   ├── WorkoutPlan.swift       — Data types (WorkoutPlan, WorkoutVideo, ActivityType)
│   │   └── SessionModel.swift      — In-session progress tracking
│   ├── Views/
│   │   ├── Auth/WelcomeView.swift  — Sign in / create account screen
│   │   ├── Setup/HomeView.swift    — Home screen, saved plans list
│   │   ├── Setup/SetupView.swift   — Time + calorie input, plan generation
│   │   ├── Plan/PlanView.swift     — Video playlist, progress chart, pro tips
│   │   └── Player/PlayerView.swift — Inline YouTube player (WKWebView)
│   ├── Services/
│   │   ├── YouTubeService.swift    — YouTube Data API v3 integration
│   │   └── BlazeConfig.swift       — API keys (add yours here before running)
│   └── Theme/
│       └── BlazeTheme.swift        — Colours, typography, spacing, corner radii
├── docs/
│   └── architecture-and-gtm.md    — Architecture decisions and cheapest path to market
└── README.md
```

---

## Setup — step by step

### Before you open Xcode

1. **Get a YouTube Data API v3 key**
   - Go to console.cloud.google.com
   - Create a project → Enable "YouTube Data API v3" → Create credentials → API key
   - Paste it into `Blaze/Services/BlazeConfig.swift` as `youtubeAPIKey`

2. **Set up Supabase** (for auth and saved plans)
   - Go to supabase.com → New project (free tier)
   - Copy the Project URL and anon key into `BlazeConfig.swift`

3. **Apple Developer account** (required to run on a real iPhone or submit to App Store)
   - Enrol at developer.apple.com ($99/year)

### Open the project in Xcode

1. Open Xcode 15+
2. File → New → Project → iOS → App
3. Settings:
   - Product Name: `Blaze`
   - Bundle Identifier: `com.yourname.blaze`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment Target: `iOS 17.0`
4. Copy all files from `Blaze/` (this folder) into the new Xcode project, preserving the folder groups
5. Add the `WebKit` framework: Project → Target → Frameworks, Libraries, and Embedded Content → + → WebKit.framework

### Add Info.plist entries

Add the following to your app's `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>youtube.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        <key>googleapis.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

---

## Architecture decisions

See [docs/architecture-and-gtm.md](docs/architecture-and-gtm.md) for the full breakdown, including:
- Why Supabase + OpenAI + YouTube Data API v3
- Cost at launch (~$99/year + ~$10/month)
- How to scale for peak traffic (5–11 am and 2–8 pm PDT)
- Freemium revenue model recommendation

---

## Technology stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 17 `@Observable` pattern) |
| Video playback | WKWebView + YouTube iFrame |
| Charts | Swift Charts (built-in) |
| Auth + database | Supabase (free tier) |
| Workout search | YouTube Data API v3 |
| State management | `@Observable`, `@AppStorage` |

---

## Monthly running cost at launch

| Item | Cost |
|---|---|
| Apple Developer Programme | $99/year |
| Supabase (free tier, up to 50k users) | $0/month |
| YouTube Data API v3 | $0/month |
| OpenAI GPT-4o (optional — for AI plan narration) | ~$5–15/month |
| **Total** | **~$99/year + ~$10/month** |
