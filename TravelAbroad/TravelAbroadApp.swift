//
//  TravelAbroadApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import Foundation
import GooglePlacesSwift
import SwiftUI

@main
struct TravelAbroadApp: App {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("shouldShowOnboarding") private var shouldShowOnboarding = false
//    @State private var isAuthenticated = false

    init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let apiKey = dict["GooglePlacesAPIKey"] as? String
        {
            PlacesClient.provideAPIKey(apiKey)
        } else {
            print("⚠️ Failed to load Google Places API Key")
        }
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
                    .onChange(of: isAuthenticated) { oldValue, newValue in
                        // Reset onboarding flag when user logs out
                        if !newValue {
                            shouldShowOnboarding = false
                        }
                    }
            }
        }
    }
}

// Google places API should be good for getting images of the places the user wants to add a rec for
