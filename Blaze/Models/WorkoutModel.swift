import SwiftUI
import Observation
import OSLog

@Observable
final class WorkoutModel {
    private let log = Logger(subsystem: "com.blaze.app", category: "WorkoutModel")

    // Inputs from SetupView
    var targetMinutes: Int = 30
    var targetCalories: Int = 300

    // Generated plan
    var currentPlan: WorkoutPlan? = nil
    var savedPlans: [WorkoutPlan] = []

    // Loading / error state
    var isGenerating: Bool = false
    var errorMessage: String? = nil

    @ObservationIgnored @AppStorage("blaze_saved_plans") private var storedPlans: Data = Data()

    init() {
        loadSavedPlans()
    }

    // MARK: - Plan generation

    func generatePlan(service: YouTubeService = YouTubeService.shared) async {
        isGenerating = true
        errorMessage = nil

        do {
            let plan = try await service.buildWorkoutPlan(
                targetMinutes: targetMinutes,
                targetCalories: targetCalories
            )
            await MainActor.run {
                self.currentPlan = plan
                self.isGenerating = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
            log.error("Plan generation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Saved plans

    func saveCurrentPlan() {
        guard let plan = currentPlan else { return }
        // Replace existing if same id, otherwise append
        if let idx = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[idx] = plan
        } else {
            savedPlans.append(plan)
        }
        persistPlans()
    }

    func deletePlan(id: UUID) {
        savedPlans.removeAll { $0.id == id }
        persistPlans()
    }

    func resumePlan(_ plan: WorkoutPlan) {
        currentPlan = plan
    }

    // Swaps a blocked video in the current plan for a working replacement
    func replaceVideo(id: String, with replacement: WorkoutVideo) {
        guard let idx = currentPlan?.videos.firstIndex(where: { $0.id == id }) else { return }
        currentPlan?.videos[idx] = replacement
    }

    // MARK: - Persistence

    private func persistPlans() {
        if let data = try? JSONEncoder().encode(savedPlans) {
            storedPlans = data
        }
    }

    private func loadSavedPlans() {
        guard !storedPlans.isEmpty,
              let plans = try? JSONDecoder().decode([WorkoutPlan].self, from: storedPlans) else { return }
        savedPlans = plans
    }
}
