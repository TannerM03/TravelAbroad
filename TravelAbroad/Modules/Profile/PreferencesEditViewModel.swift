//
//  PreferencesEditViewModel.swift
//  TravelAbroad
//
//  Created for managing preferences editing functionality
//

import Foundation
import Observation

@MainActor
@Observable
class PreferencesEditViewModel {
    var preferences: UserPreferences?
    var isLoading = false
    var isSaving = false
    var showError = false
    var errorMessage = ""
    
    func loadPreferences() async {
        isLoading = true
        
        do {
            preferences = try await SupabaseManager.shared.fetchUserPreferences()
            
            // If no preferences exist, create default ones
            if preferences == nil {
                if let userId = SupabaseManager.shared.supabase.auth.currentUser?.id {
                    preferences = UserPreferences(userId: userId)
                    print("📝 Created default preferences for user")
                }
            } else {
                print("✅ Loaded existing preferences")
            }
        } catch {
            showError = true
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            print("❌ Error loading preferences: \(error)")
        }
        
        isLoading = false
    }
    
    func savePreferences() async {
        guard let preferences = preferences else {
            showError = true
            errorMessage = "No preferences to save"
            return
        }
        
        isSaving = true
        
        do {
            // Update the timestamp before saving
            var updatedPreferences = preferences
            updatedPreferences.updatedAt = Date()
            
            try await SupabaseManager.shared.saveUserPreferences(updatedPreferences)
            
            // Update local copy with new timestamp
            self.preferences = updatedPreferences
            
            print("✅ Preferences saved successfully")
            
        } catch {
            showError = true
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            print("❌ Error saving preferences: \(error)")
        }
        
        isSaving = false
    }
}
