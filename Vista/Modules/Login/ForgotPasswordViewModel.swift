//
//  ForgotPasswordViewModel.swift
//  Vista
//
//  Password reset email request logic
//

import Foundation
import Observation

@MainActor
@Observable
class ForgotPasswordViewModel {
    var email: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    func sendResetEmail() async {
        // Clear previous messages
        clearMessages()

        // Validate email
        guard validateEmail() else {
            errorMessage = "Please enter a valid email address"
            return
        }

        isLoading = true

        do {
            try await SupabaseManager.shared.sendPasswordResetEmail(email: email)
            successMessage = "Check your email for a password reset link"
            email = "" // Clear email field after success
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func validateEmail() -> Bool {
        // Basic email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func handleError(_ error: Error) {
        let errorString = error.localizedDescription.lowercased()

        // Handle specific error cases
        if errorString.contains("user not found") || errorString.contains("no user") {
            errorMessage = "No account found with this email address"
        } else if errorString.contains("too many requests") || errorString.contains("rate limit") {
            errorMessage = "Password reset email already sent. Please check your inbox or try again in 60 seconds."
        } else if errorString.contains("network") || errorString.contains("connection") {
            errorMessage = "Unable to send email. Please check your connection."
        } else {
            errorMessage = "An error occurred. Please try again."
        }

        print("❌ Password reset error: \(error)")
    }
}
