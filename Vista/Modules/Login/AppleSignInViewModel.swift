//
//  AppleSignInViewModel.swift
//  Vista
//
//  Created for Sign In with Apple integration
//

import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
class AppleSignInViewModel {
    var isLoading: Bool = false
    var errorMessage: String?
    var isAuthenticated: Bool = false
    var shouldShowOnboarding: Bool = false

    // Account linking state
    var showAccountLinkingDialog: Bool = false
    var existingAccountEmail: String?
    var pendingAppleIDToken: String?
    var linkingPassword: String = ""
    var linkingError: String?

    // Store Apple user data for use during onboarding
    private let appleUserDataKey = "AppleUserData"

    func handleSignInWithApple(authorization: ASAuthorization) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AppleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])
            }

            guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                throw NSError(domain: "AppleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
            }

            // proceed with normal sign-in
            try await completeAppleSignIn(idToken: idToken, fullName: credential.fullName, email: credential.email)

        } catch {
            print("Sign In with Apple failed: \(error.localizedDescription)")
            errorMessage = translateError(error)
            isAuthenticated = false
            shouldShowOnboarding = false
        }

        isLoading = false
    }

    func completeAppleSignIn(idToken: String, fullName: PersonNameComponents?, email: String?) async throws {
        // Sign in with Supabase using Apple ID token
        try await SupabaseManager.shared.supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken
            )
        )

        // Apple only provides name on FIRST sign-in, so save it for later use
        if let fullName = fullName,
           fullName.givenName != nil || fullName.familyName != nil
        {
            saveAppleUserData(fullName: fullName, email: email)
        } else {
            print("⚠️ Apple did not provide name data - user may have signed in before")
        }

        // Get current user ID
        let userId = try await SupabaseManager.shared.supabase.auth.user().id

        // Check if user has completed onboarding
        let hasCompletedOnboarding = try await SupabaseManager.shared.hasCompletedOnboarding(userId: userId)

        // Update authentication state
        isAuthenticated = true
        shouldShowOnboarding = !hasCompletedOnboarding

        print("Sign In with Apple successful - User ID: \(userId.uuidString)")
    }

    func handleSignInError(_ error: Error) {
        print("Apple authorization error: \(error.localizedDescription)")

        // Don't show error for user cancellation
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled
        {
            return
        }

        errorMessage = "Sign in failed. Please try again."
    }

    // MARK: - Apple User Data Storage

    private func saveAppleUserData(fullName: PersonNameComponents, email: String?) {
        var userData: [String: String] = [:]

        if let givenName = fullName.givenName, !givenName.isEmpty {
            userData["givenName"] = givenName
        }
        if let familyName = fullName.familyName, !familyName.isEmpty {
            userData["familyName"] = familyName
        }
        if let email = email, !email.isEmpty {
            userData["email"] = email
        }

        // Only save if we have at least some data
        guard !userData.isEmpty else {
            print("⚠️ No Apple user data to save (all fields empty)")
            return
        }

        print("💾 Attempting to save Apple user data: \(userData)")
        UserDefaults.standard.set(userData, forKey: appleUserDataKey)
        UserDefaults.standard.synchronize() // Force immediate write

        // Verify it was saved
        let saved = UserDefaults.standard.dictionary(forKey: appleUserDataKey)
        print("✅ Verified saved data in UserDefaults: \(saved ?? [:])")
    }

    func getAppleUserData() -> (givenName: String?, familyName: String?, email: String?) {
        print("📖 Attempting to load Apple user data from UserDefaults...")
        guard let userData = UserDefaults.standard.dictionary(forKey: appleUserDataKey) as? [String: String] else {
            print("❌ No Apple user data found in UserDefaults")
            return (nil, nil, nil)
        }

        print("✅ Loaded Apple user data: \(userData)")
        return (
            givenName: userData["givenName"],
            familyName: userData["familyName"],
            email: userData["email"]
        )
    }

    func clearAppleUserData() {
        UserDefaults.standard.removeObject(forKey: appleUserDataKey)
    }

    // MARK: - Error Translation

    private func translateError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("connection") {
            return "Network error. Please check your connection"
        }
        if errorString.contains("timeout") {
            return "Request timed out. Please try again"
        }
        if errorString.contains("invalid") {
            return "Invalid credentials. Please try again"
        }

        return "Sign in failed. Please try again"
    }
}
