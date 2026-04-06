//
//  VistaApp.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 5/19/25.
//

import Foundation
import SwiftUI
import UserNotifications
import Kingfisher

// AppDelegate to handle push notification registration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")

        // Save token to Supabase
        Task {
            do {
                try await SupabaseManager.shared.saveDeviceToken(token)
                print("✅ Device token saved to Supabase")
            } catch {
                print("❌ Failed to save device token: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}

@main
struct VistaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("shouldShowOnboarding") private var shouldShowOnboarding = false
    @AppStorage("justSignedUp") private var justSignedUp = false
    @State private var showSplash = true
    @State private var showPasswordReset = false
    @State private var passwordResetSuccess = false
//    @State private var isAuthenticated = false

    init() {
        // Configure Kingfisher for optimal performance
        configureKingfisher()
    }

    private func configureKingfisher() {
        // Memory cache configuration
        let cache = KingfisherManager.shared.cache
        cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024 // 150 MB
        cache.memoryStorage.config.countLimit = 200 // Keep 200 images
        cache.memoryStorage.config.expiration = .seconds(600) // 10 minutes

        // Disk cache configuration
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500 MB
        cache.diskStorage.config.expiration = .days(7) // Keep for 7 days

        // Download configuration
        let downloader = KingfisherManager.shared.downloader
        downloader.downloadTimeout = 30.0
        downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 12 // More concurrent downloads
        downloader.sessionConfiguration.timeoutIntervalForRequest = 30.0
        downloader.sessionConfiguration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 200 * 1024 * 1024 // 200 MB
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                Group {
                    if showPasswordReset {
                        // Show password reset confirmation screen
                        NavigationStack {
                            ResetPasswordConfirmationView(showPasswordReset: $showPasswordReset, passwordResetSuccess: $passwordResetSuccess)
                        }
                    } else if isAuthenticated {
                        if shouldShowOnboarding {
                            // Show onboarding flow for users who just signed up
                            OnboardingFlowView(shouldShowOnboarding: $shouldShowOnboarding)
                        } else {
                            // Show main app for authenticated users
                            TabBarView(isAuthenticated: $isAuthenticated)
                        }
                    } else {
                        // Show login screen for unauthenticated users
                        NavigationStack {
                            LoginView(isAuthenticated: $isAuthenticated, shouldShowOnboarding: $shouldShowOnboarding, passwordResetSuccess: $passwordResetSuccess)
                                .onChange(of: isAuthenticated) { _, newValue in
                                    // Reset onboarding flag when user logs out
                                    if !newValue {
                                        shouldShowOnboarding = false
                                    }
                                }
                        }
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }

                // Splash screen overlay
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                // Check actual session state on app launch
                await checkAuthSession()

                // Listen for auth state changes
                Task {
                    for await state in SupabaseManager.shared.supabase.auth.authStateChanges {
                        switch state.event {
                        case .signedIn:
                            isAuthenticated = true
                            // Load blocked users when signing in
                            await BlockListManager.shared.loadBlockedUsers()
                            // Request notification permission
                            await requestNotificationPermission()
                        case .signedOut, .userDeleted:
                            isAuthenticated = false
                            shouldShowOnboarding = false
                            // Clear blocked users cache on logout
                            BlockListManager.shared.clearCache()
                        case .tokenRefreshed:
                            // Token refreshed successfully, stay authenticated
                            break
                        default:
                            break
                        }
                    }
                }

                // Hide splash screen after 1 second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }

    private func checkAuthSession() async {
        do {
            // Try to get current session from Supabase
            _ = try await SupabaseManager.shared.supabase.auth.session
            // If we got here, session is valid
            isAuthenticated = true

            // Load blocked users list for safety filtering
            await BlockListManager.shared.loadBlockedUsers()

            // Request notification permission
            await requestNotificationPermission()
        } catch {
            // No valid session or session expired
            print("No valid session on launch: \(error.localizedDescription)")
            isAuthenticated = false
            shouldShowOnboarding = false

            // Clear blocked users cache on logout
            BlockListManager.shared.clearCache()
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("handle deep link func")
        print("url scheme: \(String(describing: url.scheme))")
        print("url host: \(String(describing: url.host))")
        print("url: \(url)")

        if url.scheme == "vista" && url.host == "reset-password" {
            Task {
                do {
                    // Process the password reset link with tokens
                    try await SupabaseManager.shared.supabase.auth.session(from: url)
                    print("Password reset link processed successfully!")

                    // Show password reset confirmation screen on main thread
                    await MainActor.run {
                        showPasswordReset = true
                    }
                } catch {
                    print("❌ Password reset link processing failed: \(error)")
                    // TODO: Show error alert to user
                }
            }
        } else if url.scheme == "vista" && url.host == "auth" {
            Task {
                do {
                    // Process the email confirmation
                    try await SupabaseManager.shared.supabase.auth.session(from: url)
                    print("Email confirmed successfully!")

                    // Insert username if it was stored during signup
                    if let pendingUsername = UserDefaults.standard.string(forKey: "pendingUsername") {
                        try await SupabaseManager.shared.insertUsername(username: pendingUsername)
                        print("Username inserted: \(pendingUsername)")

                        // Clean up stored username
                        UserDefaults.standard.removeObject(forKey: "pendingUsername")
                        print("Pending username cleared")
                    }

                    // Update authentication state on main thread
                    await MainActor.run {
                        print("inside main actor")
                        isAuthenticated = true
                        shouldShowOnboarding = true // Trigger onboarding for new users
                    }
                } catch {
                    print("Email confirmation failed: \(error)")
                    // Reset flag on error
                    await MainActor.run {
                        justSignedUp = false
                    }
                }
            }
        }
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ Notification permission granted")
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("⚠️ Notification permission denied")
            }
        } catch {
            print("❌ Error requesting notification permission: \(error)")
        }
    }
}
