//
//  ResetPasswordConfirmationViewModel.swift
//  Vista
//
//  Password reset confirmation logic (after email link click)
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class ResetPasswordConfirmationViewModel {
    var newPassword: String = ""
    var confirmPassword: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var passwordUpdatedSuccessfully: Bool = false

    func updatePassword() async {
        // Clear previous error
        errorMessage = nil

        // Validate passwords
        guard validatePasswords() else { return }

        isLoading = true

        do {
            try await SupabaseManager.shared.supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )

            // Verify the session is valid after password update
            _ = try await SupabaseManager.shared.supabase.auth.session

            passwordUpdatedSuccessfully = true
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func validatePasswords() -> Bool {
        // Check if passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }

        // Check password strength (at least 8 chars, 1 uppercase, 1 number)
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return false
        }

        let uppercaseCheck = newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil
        let numberCheck = newPassword.rangeOfCharacter(from: .decimalDigits) != nil

        guard uppercaseCheck && numberCheck else {
            errorMessage = "Password must contain at least 1 uppercase letter and 1 number"
            return false
        }

        return true
    }

    private func handleError(_ error: Error) {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("same") || errorString.contains("different") || errorString.contains("new password should be different") {
            errorMessage = "New password must be different from your current password"
        } else if errorString.contains("weak password") {
            errorMessage = "Password must be at least 8 characters with 1 uppercase letter and 1 number"
        } else if errorString.contains("token") || errorString.contains("expired") || errorString.contains("invalid") {
            errorMessage = "This password reset link has expired. Please request a new one."
        } else if errorString.contains("network") || errorString.contains("connection") {
            errorMessage = "Unable to update password. Please check your connection."
        } else {
            errorMessage = "An error occurred. Please try again."
        }

        print("❌ Password update error: \(error)")
    }
}
