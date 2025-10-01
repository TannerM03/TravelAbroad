//
//  OnboardingViewModel.swift
//  TravelAbroad
//
//  Created for ML-driven preference collection
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
class OnboardingViewModel {
    var currentStep: OnboardingStep = .welcome
    var preferences: UserPreferences
    var isLoading = false
    var showError = false
    var errorMessage = ""

    // Activity drag & drop state
    var draggedActivity: ActivityPreferences.ActivityType?
    var loveItActivities: [ActivityPreferences.ActivityType] = []
    var likeItActivities: [ActivityPreferences.ActivityType] = []
    var notMyFavActivities: [ActivityPreferences.ActivityType] = []

    init() {
        // Initialize with placeholder - will be updated when user is loaded
        let userId = UUID()
        preferences = UserPreferences(userId: userId)
        setupInitialActivityCategories()

        // Load actual user ID asynchronously
        Task {
            await loadCurrentUser()
        }
    }

    private func loadCurrentUser() async {
        do {
            // TODO: Get actual user ID from Supabase authentication
            // let user = try await SupabaseManager.shared.supabase.auth.user()
            // if let userId = user?.id {
            //     preferences.userId = userId
            // }

            // For now, we'll use a placeholder and leave the integration for later
            print("🔄 User ID will be loaded from Supabase authentication")
        } catch {
            print("❌ Failed to load user: \\(error)")
        }
    }

    // MARK: - Navigation Methods

    func nextStep() {
        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? currentStep
        }
    }

    func previousStep() {
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? currentStep
        }
    }

    func canProceed() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .names:
            return true // NamesView will handle validation when button is pressed
        case .travelStyle:
            return true // All have default values
        case .activityPreferences:
            return allActivitiesCategorized()
        case .walkingDistance:
            return true
        case .additionalPreferences:
            return true
        case .summary:
            return true
        }
    }

    // MARK: - Activity Preference Management

    private func setupInitialActivityCategories() {
        // Start with all activities in "Like it" category
        likeItActivities = Array(ActivityPreferences.ActivityType.allCases)
        loveItActivities = []
        notMyFavActivities = []
    }

    private func allActivitiesCategorized() -> Bool {
        let totalActivities = ActivityPreferences.ActivityType.allCases.count
        let categorizedCount = loveItActivities.count + likeItActivities.count + notMyFavActivities.count
        return categorizedCount == totalActivities
    }

    func moveActivity(_ activity: ActivityPreferences.ActivityType, to preference: ActivityPreferences.PreferenceLevel) {
        // Remove from all categories first
        loveItActivities.removeAll { $0 == activity }
        likeItActivities.removeAll { $0 == activity }
        notMyFavActivities.removeAll { $0 == activity }

        // Add to appropriate category
        switch preference {
        case .loveIt:
            loveItActivities.append(activity)
        case .likeIt:
            likeItActivities.append(activity)
        case .notMyFav:
            notMyFavActivities.append(activity)
        }

        // Update preferences model
        updateActivityPreferences()
    }

    private func updateActivityPreferences() {
        for activity in loveItActivities {
            preferences.activityPreferences.preferences[activity] = .loveIt
        }
        for activity in likeItActivities {
            preferences.activityPreferences.preferences[activity] = .likeIt
        }
        for activity in notMyFavActivities {
            preferences.activityPreferences.preferences[activity] = .notMyFav
        }
    }

    func getActivityCategory(for activity: ActivityPreferences.ActivityType) -> ActivityPreferences.PreferenceLevel {
        if loveItActivities.contains(activity) { return .loveIt }
        if likeItActivities.contains(activity) { return .likeIt }
        if notMyFavActivities.contains(activity) { return .notMyFav }
        return .likeIt // Default fallback
    }

    // MARK: - Travel Style Updates

    func updateEnergyLevel(_ level: TravelStylePreferences.EnergyLevel) {
        preferences.travelStyle.energyLevel = level
    }

    func updateSocialPreference(_ social: TravelStylePreferences.SocialPreference) {
        preferences.travelStyle.socialPreference = social
    }

    func updateTimePreference(_ time: TravelStylePreferences.TimePreference) {
        preferences.travelStyle.timePreference = time
    }

    func updateBudgetRange(_ budget: TravelStylePreferences.BudgetRange) {
        preferences.travelStyle.budgetRange = budget
    }

    // MARK: - Practical Preferences Updates

    func updateWalkingDistance(_ distance: PracticalPreferences.WalkingDistance) {
        preferences.practicalPreferences.maxWalkingDistance = distance
    }

    func updateTransportationPreference(_ transport: PracticalPreferences.TransportationPreference) {
        preferences.practicalPreferences.transportationPreference = transport
    }

    func updateAccommodationStyle(_ accommodation: PracticalPreferences.AccommodationStyle) {
        preferences.practicalPreferences.accommodationStyle = accommodation
    }

    // MARK: - Additional Preferences Updates

    func updatePlanningStyle(_ planning: AdditionalPreferences.PlanningStyle) {
        preferences.additionalPreferences.planningStyle = planning
    }

    func updateRiskTolerance(_ risk: AdditionalPreferences.RiskTolerance) {
        preferences.additionalPreferences.riskTolerance = risk
    }

    func updateCulturalImmersion(_ cultural: AdditionalPreferences.CulturalImmersion) {
        preferences.additionalPreferences.culturalImmersion = cultural
    }

    func updateCrowdTolerance(_ crowd: AdditionalPreferences.CrowdTolerance) {
        preferences.additionalPreferences.crowdTolerance = crowd
    }

    // MARK: - Save Preferences

    func completeOnboarding() async {
        isLoading = true

        do {
            // Save preferences to Supabase database
            try await SupabaseManager.shared.saveUserPreferences(preferences)

            print("✅ Onboarding completed - preferences saved")

        } catch {
            showError = true
            errorMessage = "Failed to save preferences: \\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Validation Helpers

    var progressText: String {
        "\(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)"
    }

    var canGoBack: Bool {
        currentStep != .welcome
    }

    var isLastStep: Bool {
        currentStep == .summary
    }
}
