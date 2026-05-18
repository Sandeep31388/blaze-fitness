import SwiftUI

struct HomeView: View {
    @Environment(UserModel.self)   private var userModel
    @Environment(WorkoutModel.self) private var workoutModel
    @Environment(SessionModel.self) private var sessionModel

    @State private var path = NavigationPath()
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BlazeColour.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: BlazeSpacing.xl) {

                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: BlazeSpacing.xs) {
                                Text("Hello, \(userModel.displayName)")
                                    .font(BlazeFont.heading(20))
                                    .foregroundStyle(BlazeColour.textSecondary)
                                Text("Ready to burn?")
                                    .font(BlazeFont.display(32, weight: .black))
                                    .foregroundStyle(BlazeColour.textPrimary)
                            }
                            Spacer()
                            Button(action: { showSignOutConfirm = true }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 28))
                                    .foregroundStyle(BlazeColour.textSecondary)
                            }
                        }

                        // New plan CTA
                        Button(action: { path.append(NavDestination.setup) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: BlazeSpacing.xs) {
                                    Text("New Workout Plan")
                                        .font(BlazeFont.heading(18))
                                        .foregroundStyle(BlazeColour.textPrimary)
                                    Text("Enter your time and calorie targets")
                                        .font(BlazeFont.body(14))
                                        .foregroundStyle(BlazeColour.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(BlazeColour.accent)
                            }
                            .padding(BlazeSpacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [BlazeColour.accent.opacity(0.25), BlazeColour.surface],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: BlazeRadius.lg)
                                    .stroke(BlazeColour.accent.opacity(0.4), lineWidth: 1)
                            )
                        }

                        // Saved plans
                        if !workoutModel.savedPlans.isEmpty {
                            VStack(alignment: .leading, spacing: BlazeSpacing.md) {
                                Text("Your Plans")
                                    .font(BlazeFont.heading(18))
                                    .foregroundStyle(BlazeColour.textPrimary)

                                ForEach(workoutModel.savedPlans.reversed()) { plan in
                                    SavedPlanCard(plan: plan) {
                                        workoutModel.resumePlan(plan)
                                        sessionModel.startSession()
                                        path.append(NavDestination.plan)
                                    }
                                }
                            }
                        } else {
                            EmptyPlansView()
                        }
                    }
                    .padding(BlazeSpacing.lg)
                }
            }
            .navigationDestination(for: NavDestination.self) { dest in
                switch dest {
                case .setup:  SetupView(path: $path)
                case .plan:   PlanView(path: $path)
                case .player(let video): PlayerView(video: video, path: $path)
                }
            }
        }
        .confirmationDialog("Sign out of Blaze?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { userModel.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Navigation destinations

enum NavDestination: Hashable {
    case setup
    case plan
    case player(WorkoutVideo)
}

// MARK: - Saved plan card

struct SavedPlanCard: View {
    let plan: WorkoutPlan
    let onResume: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: BlazeSpacing.xs) {
                Text(plan.name)
                    .font(BlazeFont.body(15, weight: .semibold))
                    .foregroundStyle(BlazeColour.textPrimary)
                    .lineLimit(1)

                HStack(spacing: BlazeSpacing.sm) {
                    Label("\(plan.targetMinutes) min", systemImage: "clock")
                    Label("\(plan.targetCalories) cal", systemImage: "flame")
                    Label("\(plan.videos.count) videos", systemImage: "play.rectangle")
                }
                .font(BlazeFont.caption())
                .foregroundStyle(BlazeColour.textSecondary)
            }
            Spacer()
            Button("Resume", action: onResume)
                .font(BlazeFont.body(13, weight: .semibold))
                .foregroundStyle(BlazeColour.accent)
                .padding(.horizontal, BlazeSpacing.md)
                .padding(.vertical, BlazeSpacing.sm)
                .background(BlazeColour.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
        }
        .padding(BlazeSpacing.md)
        .background(BlazeColour.card)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))
    }
}

// MARK: - Empty state

struct EmptyPlansView: View {
    var body: some View {
        VStack(spacing: BlazeSpacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(BlazeColour.textMuted)
            Text("No saved plans yet")
                .font(BlazeFont.body(16, weight: .medium))
                .foregroundStyle(BlazeColour.textSecondary)
            Text("Create a new plan above to get started.")
                .font(BlazeFont.body(14))
                .foregroundStyle(BlazeColour.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BlazeSpacing.xxl)
    }
}
