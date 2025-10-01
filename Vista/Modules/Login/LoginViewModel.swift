//
//  LoginViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/22/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class LoginViewModel {
    var loginCredential: String = ""
    var password: String = ""
    var isSignUp: Bool = false
    var errorMessage: String?
    var isLoading: Bool = false
    var showEmailConfirmationDialog: Bool = false
    private var email: String?

    func authAction() async -> Bool {
        errorMessage = nil
        isLoading = true
        do {
            if isSignUp {
                // Validate .edu email requirement
                if !loginCredential.lowercased().hasSuffix(".edu") {
                    throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please use a valid .edu email address"])
                }

                let emailAvailable = try await SupabaseManager.shared.isEmailAvailable(email: loginCredential)
                if !emailAvailable {
                    throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "This email already exists"])
                }

                try await SupabaseManager.shared.supabase.auth.signUp(email: loginCredential, password: password)

                // For signup with email confirmation, show success dialog instead of proceeding
                showEmailConfirmationDialog = true
                isLoading = false
                return false // Don't proceed to main app yet
            } else {
                if loginCredential.contains("@") {
                    try await SupabaseManager.shared.supabase.auth.signIn(email: loginCredential, password: password)
                } else {
                    email = try await SupabaseManager.shared.fetchEmailWithUsername(username: loginCredential)
                    if let email = email {
                        try await SupabaseManager.shared.supabase.auth.signIn(email: email, password: password)
                    }
                }
            }
        } catch {
            print("❌ Signup failed with error: \(error.localizedDescription)")
            errorMessage = translateError(error)
            showEmailConfirmationDialog = false // Make sure dialog is hidden on error
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }

    func hasCompletedOnboarding() async -> Bool {
        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            let userId = user.id

            return try await SupabaseManager.shared.hasCompletedOnboarding(userId: userId)
        } catch {
            print("Error checking onboarding status: \(error)")
            return false
        }
    }

    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        // Common Supabase Auth errors
        if errorString.contains("invalid login credentials") || errorString.contains("json") || errorString.contains("parsing") {
            return "Incorrect username/email or password"
        }
        if errorString.contains("email not confirmed") {
            return "Please check your email and tap the confirmation link to activate your account"
        }
        if errorString.contains("signup") || errorString.contains("confirmation") {
            return "Account created! Please check your email for a confirmation link"
        }
        if errorString.contains("user already registered") || errorString.contains("already exists") {
            return "Account already exists. Please check your email for the confirmation link or try logging in"
        }
        if errorString.contains("weak password") || errorString.contains("password") {
            return "Password must be at least 8 characters with 1 uppercase character and 1 number"
        }
        if errorString.contains("please use a valid .edu email address") {
            return "Please use a valid .edu email address"
        }
        if errorString.contains("invalid email") {
            return "Please enter a valid email address"
        }
        if errorString.contains("rate limit") {
            return "Too many attempts. Please try again later"
        }
        if errorString.contains("network") || errorString.contains("connection") {
            return "Network error. Please check your connection"
        }
        if errorString.contains("timeout") {
            return "Request timed out. Please try again"
        }

        // Fallback for unknown errors
        return "Something went wrong. Please try again"
    }
}
