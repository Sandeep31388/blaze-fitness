import SwiftUI

struct WelcomeView: View {
    @Environment(UserModel.self) private var userModel
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var isSignUp: Bool = true
    @State private var showError: Bool = false

    var body: some View {
        ZStack {
            BlazeColour.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: BlazeSpacing.xxl) {
                    Spacer().frame(height: BlazeSpacing.xxl)

                    // Logo / wordmark
                    VStack(spacing: BlazeSpacing.sm) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(BlazeColour.accent)
                            .shadow(color: BlazeColour.accentGlow, radius: 20)

                        Text("BLAZE")
                            .font(BlazeFont.display(42, weight: .black))
                            .foregroundStyle(BlazeColour.textPrimary)
                            .tracking(8)

                        Text("Your workout. Your pace. Your results.")
                            .font(BlazeFont.body(15))
                            .foregroundStyle(BlazeColour.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Form card
                    VStack(spacing: BlazeSpacing.md) {
                        if isSignUp {
                            BlazeTextField(label: "Your name", text: $name,
                                           icon: "person.fill",
                                           keyboard: .default)
                        }

                        BlazeTextField(label: "Email address", text: $email,
                                       icon: "envelope.fill",
                                       keyboard: .emailAddress)

                        if showError {
                            Text("Please fill in all fields to continue.")
                                .font(BlazeFont.caption())
                                .foregroundStyle(BlazeColour.destructive)
                        }
                    }
                    .padding(BlazeSpacing.lg)
                    .background(BlazeColour.card)
                    .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.lg))

                    // Primary CTA
                    Button(action: handleCTA) {
                        Text(isSignUp ? "Create my account" : "Sign in")
                            .font(BlazeFont.body(17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BlazeSpacing.md)
                            .background(BlazeColour.accent)
                            .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.pill))
                            .shadow(color: BlazeColour.accentGlow, radius: 12)
                    }

                    // Toggle sign-in / sign-up
                    Button(action: { isSignUp.toggle(); showError = false }) {
                        Text(isSignUp
                             ? "Already have an account? Sign in"
                             : "New here? Create an account")
                            .font(BlazeFont.body(14))
                            .foregroundStyle(BlazeColour.textSecondary)
                    }

                    Spacer().frame(height: BlazeSpacing.xxl)
                }
                .padding(.horizontal, BlazeSpacing.lg)
            }
        }
    }

    private func handleCTA() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName  = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty || (isSignUp && trimmedName.isEmpty) {
            showError = true
            return
        }

        let displayName = isSignUp ? trimmedName : trimmedEmail.components(separatedBy: "@").first ?? "Athlete"
        userModel.signIn(email: trimmedEmail, name: displayName)
    }
}

// MARK: - Reusable text field component

struct BlazeTextField: View {
    let label: String
    @Binding var text: String
    let icon: String
    let keyboard: UIKeyboardType

    var body: some View {
        HStack(spacing: BlazeSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(BlazeColour.textMuted)
                .frame(width: 20)

            TextField("", text: $text, prompt:
                Text(label).foregroundColor(BlazeColour.textMuted))
                .font(BlazeFont.body())
                .foregroundStyle(BlazeColour.textPrimary)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
        }
        .padding(BlazeSpacing.md)
        .background(BlazeColour.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: BlazeRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: BlazeRadius.md)
                .stroke(BlazeColour.textMuted.opacity(0.3), lineWidth: 1)
        )
    }
}
