import SwiftUI

struct SetupView: View {
    @Environment(WorkoutModel.self) private var workoutModel
    @Environment(SessionModel.self) private var sessionModel
    @Binding var path: NavigationPath

    // Local draft values — only commit to model when user taps Generate
    @State private var minutes: Int = 30
    @State private var calories: Int = 300

    private let minuteOptions  = [10, 15, 20, 30, 45, 60, 75, 90]
    private let calorieOptions = [100, 150, 200, 250, 300, 400, 500, 600, 750]

    var body: some View {
        ZStack {
            BlazeColour.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: BlazeSpacing.xl) {

                    // Title
                    VStack(alignment: .leading, spacing: BlazeSpacing.xs) {
                        Text("Set Your Targets")
                            .font(BlazeFont.display(28, weight: .black))
                            .foregroundStyle(BlazeColour.textPrimary)
                        Text("Blaze builds a personalised playlist around your goals.")
                            .font(BlazeFont.body(15))
                            .foregroundStyle(BlazeColour.textSecondary)
                    }

                    // Time picker
                    TargetSectionView(
                        title: "How long?",
                        subtitle: "Minutes",
                        icon: "clock.fill",
                        value: "\(minutes)",
                        unit: "min"
                    ) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BlazeSpacing.sm) {
                                ForEach(minuteOptions, id: \.self) { opt in
                                    PillButton(
                                        label: "\(opt)",
                                        isSelected: minutes == opt,
                                        action: { minutes = opt }
                                    )
                                }
                            }
                            .padding(.horizontal, BlazeSpacing.xs)
                        }
                    }

                    // Calories picker
                    TargetSectionView(
                        title: "How many calories?",
                        subtitle: "Estimated burn",
                        icon: "flame.fill",
                        value: "\(calories)",
                        unit: "cal"
                    ) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BlazeSpacing.sm) {
                                ForEach(calorieOptions, id: \.self) { opt in
                                    PillButton(
                                        label: "\(opt)",
                                        isSelected: calories == opt,
                                        action: { calories = opt }
                                    )
                                }
                            }
                            .padding(.horizontal, BlazeSpacing.xs)
                        }
                    }

                    // Intensity hint
                    let cpm = Double(calories) / Double(minutes)
                    IntensityBadge(caloriesPerMinute: cpm)

                    // Generate CTA
                    Button(action: generate) {
                        HStack {
                            if workoutModel.isGenerating {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, BlazeSpacing.xs)
                                Text("Building your plan…")
                            } else {
                                Image(systemName: "flame.fill")
                                Text("Build My Plan")
                            }
                        }
                        .font(BlazeFont.body(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BlazeSpacing.md)
                        .background(workoutModel.isGenerating
                                    ? BlazeColour.accent.opacity(0.5)
                                    : BlazeColour.accent)
                        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                        .shadow(color: BlazeColour.accentGlow, radius: 16)
                    }
                    .disabled(workoutModel.isGenerating)

                    if let err = workoutModel.errorMessage {
                        Text(err)
                            .font(BlazeFont.caption())
                            .foregroundStyle(BlazeColour.destructive)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer().frame(height: BlazeSpacing.xxl)
                }
                .padding(BlazeSpacing.lg)
            }
        }
        .navigationTitle("New Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func generate() {
        @Bindable var wm = workoutModel
        wm.targetMinutes  = minutes
        wm.targetCalories = calories

        Task {
            await workoutModel.generatePlan()
            if workoutModel.currentPlan != nil {
                sessionModel.startSession()
                path.append(NavDestination.plan)
            }
        }
    }
}

// MARK: - Supporting views

struct TargetSectionView<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let value: String
    let unit: String
    @ViewBuilder let picker: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: BlazeSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(BlazeColour.accent)
                Text(title)
                    .font(BlazeFont.heading(17))
                    .foregroundStyle(BlazeColour.textPrimary)
                Spacer()
                Text("\(value) \(unit)")
                    .font(BlazeFont.label(20, weight: .bold))
                    .foregroundStyle(BlazeColour.accent)
            }
            picker()
        }
        .padding(BlazeSpacing.lg)
        .background(BlazeColour.card)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.lg))
    }
}

struct PillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(BlazeFont.body(15, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : BlazeColour.textSecondary)
                .padding(.horizontal, BlazeSpacing.md)
                .padding(.vertical, BlazeSpacing.sm)
                .background(isSelected ? BlazeColour.accent : BlazeColour.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                .overlay(
                    RoundedRectangle(cornerRadius: BlazeRadius.pill)
                        .stroke(isSelected ? BlazeColour.accent : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct IntensityBadge: View {
    let caloriesPerMinute: Double

    var label: String {
        switch caloriesPerMinute {
        case ..<4:    return "Light — yoga, pilates, walking"
        case 4..<7:   return "Moderate — brisk walk, strength"
        case 7..<10:  return "High — jogging, cycling"
        default:       return "Intense — HIIT, jump rope"
        }
    }

    var colour: Color {
        switch caloriesPerMinute {
        case ..<4:    return BlazeColour.success
        case 4..<7:   return BlazeColour.warning
        case 7..<10:  return BlazeColour.accentSecondary
        default:       return BlazeColour.accent
        }
    }

    var body: some View {
        HStack(spacing: BlazeSpacing.sm) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 13))
            Text(label)
                .font(BlazeFont.body(13, weight: .medium))
        }
        .foregroundStyle(colour)
        .padding(.horizontal, BlazeSpacing.md)
        .padding(.vertical, BlazeSpacing.sm)
        .background(colour.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
    }
}
