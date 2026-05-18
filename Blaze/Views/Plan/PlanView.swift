import SwiftUI
import Charts

struct PlanView: View {
    @Environment(WorkoutModel.self)  private var workoutModel
    @Environment(SessionModel.self)  private var sessionModel
    @Binding var path: NavigationPath
    @State private var showExitConfirm = false

    var body: some View {
        ZStack {
            BlazeColour.background.ignoresSafeArea()

            if let plan = workoutModel.currentPlan {
                ScrollView {
                    VStack(spacing: BlazeSpacing.xl) {

                        ProgressHeaderView(
                            plan: plan,
                            session: sessionModel,
                            onExit: { showExitConfirm = true }
                        )

                        PlanSummaryRow(plan: plan)

                        VStack(spacing: BlazeSpacing.md) {
                            ForEach(Array(plan.videos.enumerated()), id: \.element.id) { index, video in
                                VideoCard(
                                    video: video,
                                    index: index + 1,
                                    isCompleted: sessionModel.isCompleted(videoID: video.id),
                                    onTap: {
                                        sessionModel.currentVideoID = video.id
                                        path.append(NavDestination.player(video))
                                    },
                                    onMark: {
                                        sessionModel.markCompleted(videoID: video.id)
                                    }
                                )
                            }
                        }

                        Button(action: { workoutModel.saveCurrentPlan() }) {
                            Label("Save this plan", systemImage: "bookmark.fill")
                                .font(BlazeFont.body(15, weight: .medium))
                                .foregroundStyle(BlazeColour.textSecondary)
                        }
                        .padding(.bottom, BlazeSpacing.xxl)
                    }
                    .padding(BlazeSpacing.lg)
                }
            } else {
                Text("No plan loaded.")
                    .foregroundStyle(BlazeColour.textSecondary)
            }
        }
        .navigationTitle("Your Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Exit this workout?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Exit and clear progress", role: .destructive) {
                sessionModel.endSession()
                workoutModel.currentPlan = nil
                path = NavigationPath()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your progress in this session will be deleted.")
        }
    }
}

// MARK: - Progress header (pie chart + Exit)

struct ProgressHeaderView: View {
    let plan: WorkoutPlan
    let session: SessionModel
    let onExit: () -> Void

    private var completedCount: Int { session.completedVideoIDs.count }
    private var totalCount: Int     { plan.videos.count }
    private var fraction: Double    { session.progressFraction(totalVideos: totalCount) }
    private var percent: Int        { Int(fraction * 100) }

    var body: some View {
        HStack(alignment: .center, spacing: BlazeSpacing.lg) {

            ZStack {
                Chart {
                    SectorMark(
                        angle: .value("Done", max(fraction, 0.001)),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(BlazeColour.progressDone)

                    SectorMark(
                        angle: .value("Remaining", max(1 - fraction, 0.001)),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(BlazeColour.progressRemaining)
                }
                .frame(width: 90, height: 90)

                Text("\(percent)%")
                    .font(BlazeFont.label(16, weight: .bold))
                    .foregroundStyle(BlazeColour.textPrimary)
            }

            VStack(alignment: .leading, spacing: BlazeSpacing.sm) {
                Text("\(completedCount) of \(totalCount) videos done")
                    .font(BlazeFont.body(15, weight: .semibold))
                    .foregroundStyle(BlazeColour.textPrimary)

                Text("\(plan.totalMinutes) min · \(plan.totalCalories) cal total")
                    .font(BlazeFont.caption())
                    .foregroundStyle(BlazeColour.textSecondary)

                Button(action: onExit) {
                    Label("Exit", systemImage: "xmark.circle.fill")
                        .font(BlazeFont.body(13, weight: .semibold))
                        .foregroundStyle(BlazeColour.destructive)
                        .padding(.horizontal, BlazeSpacing.md)
                        .padding(.vertical, BlazeSpacing.xs)
                        .background(BlazeColour.destructive.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                }
            }

            Spacer()
        }
        .padding(BlazeSpacing.lg)
        .background(BlazeColour.card)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.lg))
    }
}

// MARK: - Plan summary row

struct PlanSummaryRow: View {
    let plan: WorkoutPlan

    var body: some View {
        HStack(spacing: BlazeSpacing.lg) {
            StatChip(icon: "clock.fill",  value: "\(plan.targetMinutes)", unit: "min")
            StatChip(icon: "flame.fill",  value: "\(plan.targetCalories)", unit: "cal")
            StatChip(icon: "play.rectangle.fill", value: "\(plan.videos.count)", unit: "videos")
        }
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: BlazeSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(BlazeColour.accent)
            Text("\(value) \(unit)")
                .font(BlazeFont.body(13, weight: .medium))
                .foregroundStyle(BlazeColour.textSecondary)
        }
        .padding(.horizontal, BlazeSpacing.sm)
        .padding(.vertical, BlazeSpacing.xs)
        .background(BlazeColour.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
    }
}

// MARK: - Video card

struct VideoCard: View {
    let video: WorkoutVideo
    let index: Int
    let isCompleted: Bool
    let onTap: () -> Void
    let onMark: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Button(action: onTap) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(16/9, contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(BlazeColour.surfaceElevated)
                                .aspectRatio(16/9, contentMode: .fill)
                                .overlay(
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(BlazeColour.textMuted)
                                )
                        }
                    }
                    .clipped()
                    .overlay(
                        isCompleted
                        ? AnyView(
                            Color.black.opacity(0.6)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(BlazeColour.success)
                                )
                        )
                        : AnyView(Color.clear)
                    )

                    if !isCompleted {
                        HStack(spacing: BlazeSpacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                            Text("Play")
                                .font(BlazeFont.body(12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, BlazeSpacing.sm)
                        .padding(.vertical, BlazeSpacing.xs)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.sm))
                        .padding(BlazeSpacing.sm)
                    }

                    Text(video.activityType.rawValue.uppercased())
                        .font(BlazeFont.caption(10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, BlazeSpacing.sm)
                        .padding(.vertical, 3)
                        .background(BlazeColour.accent)
                        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.sm))
                        .padding(BlazeSpacing.sm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md, style: .continuous))
            }

            VStack(alignment: .leading, spacing: BlazeSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(index). \(video.title)")
                            .font(BlazeFont.body(14, weight: .semibold))
                            .foregroundStyle(BlazeColour.textPrimary)
                            .lineLimit(2)
                        Text(video.channelName)
                            .font(BlazeFont.caption())
                            .foregroundStyle(BlazeColour.textMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Label(video.formattedDuration, systemImage: "clock")
                            .font(BlazeFont.caption())
                            .foregroundStyle(BlazeColour.textSecondary)
                        Label("\(video.estimatedCalories) cal", systemImage: "flame")
                            .font(BlazeFont.caption())
                            .foregroundStyle(BlazeColour.accentSecondary)
                    }
                }

                HStack(alignment: .top, spacing: BlazeSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(BlazeColour.warning)
                    Text(video.proTip)
                        .font(BlazeFont.caption(12))
                        .foregroundStyle(BlazeColour.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(BlazeSpacing.sm)
                .background(BlazeColour.warning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.sm))

                if !isCompleted {
                    Button(action: onMark) {
                        Label("Mark as done", systemImage: "checkmark.circle")
                            .font(BlazeFont.body(12, weight: .medium))
                            .foregroundStyle(BlazeColour.success)
                    }
                }
            }
            .padding(BlazeSpacing.md)
        }
        .background(BlazeColour.card)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.lg))
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}
