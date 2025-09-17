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
//    @State private var isAuthenticated = false

    init() {
        // App initialization
    }

    var body: some Scene {
        WindowGroup {
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
    }
}
