//
//  LoginViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/22/25.
//

import Foundation
import Supabase

@MainActor
class LoginViewModel: ObservableObject {
    @Published var loginCredential: String = ""
    @Published var password: String = ""
    @Published var isSignUp: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var username: String = ""
    private var email: String? = nil

    func authAction() async -> Bool {
        errorMessage = nil
        isLoading = true
        do {
            if isSignUp {
                // Check username availability first
                let isAvailable = try await SupabaseManager.shared.isUsernameAvailable(username: username)
                if !isAvailable {
                    throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "This username is already taken"])
                }

                try await SupabaseManager.shared.supabase.auth.signUp(email: loginCredential, password: password)
                try await SupabaseManager.shared.insertUsername(username: username)
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
            errorMessage = translateError(error)
            isLoading = false
            return false
        }
        isLoading = false
        return true
    }

    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        // Common Supabase Auth errors
        if errorString.contains("invalid login credentials") || errorString.contains("json") || errorString.contains("parsing") {
            return "Incorrect username/email or password"
        }
        if errorString.contains("email not confirmed") {
            return "Please check your email and confirm your account"
        }
        if errorString.contains("user already registered") || errorString.contains("already exists") {
            return "This email is already registered"
        }
        if errorString.contains("unique") && errorString.contains("username") {
            return "This username is already taken"
        }
        if errorString.contains("this username is already taken") {
            return "This username is already taken"
        }
        if errorString.contains("weak password") || errorString.contains("password") {
            return "Password must be at least 8 characters with 1 uppercase character and 1 number"
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
