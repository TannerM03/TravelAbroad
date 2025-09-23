//
//  TravelAbroadApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import Foundation
import SwiftUI

@main
struct TravelAbroadApp: App {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("shouldShowOnboarding") private var shouldShowOnboarding = false
    @AppStorage("justSignedUp") private var justSignedUp = false
//    @State private var isAuthenticated = false

    init() {
        // App initialization
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    if shouldShowOnboarding {
                        // Show onboarding flow for users who just signed up
                        OnboardingFlowView(shouldShowOnboarding: $shouldShowOnboarding)
                    } else {
                        // Show main app for authenticated users
                        TabBarView(isAuthenticated: $isAuthenticated)
                    }
                } else {
                    // Show login screen for unauthenticated users
                    LoginView(isAuthenticated: $isAuthenticated, shouldShowOnboarding: $shouldShowOnboarding)
                        .onChange(of: isAuthenticated) { _, newValue in
                            // Reset onboarding flag when user logs out
                            if !newValue {
                                shouldShowOnboarding = false
                            }
                        }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("handle deep link func")
        print("url scheme: \(String(describing: url.scheme))")
        print("url host: \(String(describing: url.host))")
        print("url: \(url)")
        if url.scheme == "travelabroad" && url.host == "auth" {
            Task {
                do {
                    // Process the email confirmation
                    try await SupabaseManager.shared.supabase.auth.session(from: url)
                    print("✅ Email confirmed successfully!")

                    // Insert username if it was stored during signup
                    if let pendingUsername = UserDefaults.standard.string(forKey: "pendingUsername") {
                        try await SupabaseManager.shared.insertUsername(username: pendingUsername)
                        print("✅ Username inserted: \(pendingUsername)")

                        // Clean up stored username
                        UserDefaults.standard.removeObject(forKey: "pendingUsername")
                        print("✅ Pending username cleared")
                    }

                    // Update authentication state on main thread
                    await MainActor.run {
                        print("inside main actor")
                        isAuthenticated = true
                        shouldShowOnboarding = true // Trigger onboarding for new users
                    }
                } catch {
                    print("❌ Email confirmation failed: \(error)")
                    // Reset flag on error
                    await MainActor.run {
                        justSignedUp = false
                    }
                }
            }
        }
    }
}
