# Blaze — Architecture, Technology, and Go-to-Market Plan

_Drafted: 18 May 2026_

---

## What Blaze Does

Blaze is an iOS workout planner app. A user enters how many minutes they want to exercise and how many calories they want to burn. The app generates a personalised step-by-step workout plan — including walking, jogging, and strength activities — and curates a YouTube playlist of workout videos that fits exactly within the time and calorie targets. Users track their progress through the session and can exit at any time to start fresh.

---

## Recommended Technology Stack

### iOS App

| Layer | Technology | Why |
|---|---|---|
| Language | Swift 5.9 | Apple's standard. Required for modern SwiftUI. |
| UI framework | SwiftUI | Declarative UI. Matches PourCraft's pattern. Less code than UIKit. |
| State management | `@Observable` macro (iOS 17+) | Same pattern as PourCraft's `BrewModel`. Clean, testable. |
| Persistence | `@AppStorage` + `UserDefaults` | Lightweight. Sufficient for user profiles and saved workout plans. |
| Video playback | `WKWebView` + YouTube iFrame API | Embeds YouTube videos natively inside the app. Free. No licensing cost. |
| Charts | Swift Charts (built-in, iOS 16+) | Native pie chart for progress view. No third-party dependency. |
| Navigation | SwiftUI `NavigationStack` + custom `TabBar` | Matches PourCraft's `ZineTabBar` pattern. |
| Design system | IntuitUIComponents is **not** used here — Blaze is a consumer app, not an Intuit product. Use a custom dark-mode design system built on SwiftUI's native theming. | — |

### Backend

| Layer | Technology | Why |
|---|---|---|
| API gateway + auth | **Supabase** (free tier to start) | Provides user authentication (email/password, Apple Sign-In), a Postgres database, and a REST API — all in one. Free up to 500MB / 50,000 monthly active users. |
| Workout plan generation | **OpenAI GPT-4o API** | Generates personalised step-by-step workout plans based on time and calorie inputs. Pay-per-use. No server needed. |
| YouTube search | **YouTube Data API v3** | Searches YouTube for workout videos matching the activity. Free quota: 10,000 units/day. Sufficient for MVP. |
| Hosting (if needed) | **Supabase Edge Functions** | Serverless. Only pay for usage. No idle server costs. |

### Scalability for Peak Traffic (5–11 am PDT, 2–8 pm PDT)

The architecture is **serverless by design**. There are no always-on servers to provision or scale.

- **Supabase** auto-scales its Postgres connection pooler (PgBouncer) and Edge Functions horizontally. At medium traffic (~10,000 daily active users), the Pro plan ($25/month) is sufficient.
- **OpenAI API** scales automatically. No infrastructure management required.
- **YouTube Data API v3** has per-project quotas. At high traffic, request a quota increase from Google Cloud Console — free of charge, processed within 24 hours.
- **CDN caching:** Cache YouTube search results in Supabase by query hash + calorie/time parameters. This dramatically reduces API quota consumption at peak. A cache TTL of 24 hours is appropriate for workout video results.

At medium-to-high traffic (100,000+ DAU), the recommended upgrade path is:

1. Move workout plan generation to a dedicated Supabase Edge Function with a Redis cache layer (Upstash, ~$0/month for low volume).
2. Upgrade Supabase to the Team plan ($599/month) for dedicated compute and higher connection limits.
3. Add a CloudFront or Fastly CDN in front of any static assets.

---

## Architecture Diagram (Text)

```
iPhone (SwiftUI App)
    │
    ├── Auth → Supabase Auth (Apple Sign-In / Email)
    │
    ├── Workout Plan Generation
    │       └── Supabase Edge Function
    │               └── OpenAI GPT-4o API
    │
    ├── YouTube Search
    │       └── Supabase Edge Function (cached)
    │               └── YouTube Data API v3
    │
    ├── User Data (saved plans, progress)
    │       └── Supabase Postgres
    │
    └── Video Playback → WKWebView (YouTube iFrame, no backend)
```

---

## Cheapest Path to Market

This is the most important question. Here is the honest answer.

### What it costs to launch (MVP — first 6 months)

| Item | Cost |
|---|---|
| Apple Developer Programme (required to publish on App Store) | $99/year |
| Supabase free tier | $0/month (up to 500MB, 50,000 MAU) |
| OpenAI API (GPT-4o, ~500 plan generations/month at launch) | ~$5–$15/month |
| YouTube Data API v3 | $0/month (10,000 units/day free quota) |
| Domain name (optional, for a marketing page) | ~$12/year |
| **Total at launch** | **~$99/year + ~$10/month** |

### When you start growing (5,000–50,000 MAU)

| Item | Cost |
|---|---|
| Supabase Pro | $25/month |
| OpenAI API (higher volume) | $50–$150/month |
| YouTube Data API v3 (with caching) | $0 |
| **Total at scale** | **~$75–$175/month** |

### Revenue model recommendation

The fastest path to revenue is a **freemium model**:

- **Free:** 3 workout plans per week, standard video quality, no saved history.
- **Blaze Pro ($4.99/month or $39.99/year):** Unlimited plans, saved workout history, offline mode, premium video curation.

Use Apple's **StoreKit 2** (built into iOS) for in-app subscription management. No third-party payment provider needed.

---

## App Architecture — Following PourCraft's Pattern

PourCraft uses:
- `@Observable` macro on a single model class
- `@State` ownership of that model at the app entry point
- `@Bindable` for passing reactive bindings into child views
- `@AppStorage` for lightweight preference persistence
- Custom `TabBar` for navigation

Blaze follows the same pattern, extended across three models:

| Model | Owns |
|---|---|
| `UserModel` | Auth state, user profile, saved plans |
| `WorkoutModel` | Current plan, video playlist, calorie/time targets |
| `SessionModel` | Active workout session progress (video completion, elapsed time) |

---

## Screen Flow

```
Launch
  └── WelcomeView (sign in / create account)
        └── HomeView (new plan / continue plan)
              └── SetupView (enter minutes + calories)
                    └── PlanView (video playlist + pro tips + progress chart)
                          ├── PlayerView (inline YouTube video)
                          └── Exit → HomeView (clears session)
```

---

## What You Need to Do Before Building

1. **Create a free Supabase project** at supabase.com. Takes 5 minutes. Save the project URL and API key — you will add these to the app's config file.
2. **Enable the YouTube Data API v3** in Google Cloud Console (console.cloud.google.com). Create an API key. Free.
3. **Get an OpenAI API key** at platform.openai.com. Add a payment method. The first $5 of usage is free for new accounts.
4. **Enrol in the Apple Developer Programme** at developer.apple.com ($99/year). Required to run the app on a real iPhone and submit to the App Store.

---

_Sources:_
- Supabase pricing: https://supabase.com/pricing
- YouTube Data API v3 quota: https://developers.google.com/youtube/v3/getting-started#quota
- OpenAI pricing: https://openai.com/pricing
- Apple Developer Programme: https://developer.apple.com/programs/
- StoreKit 2: https://developer.apple.com/storekit/
