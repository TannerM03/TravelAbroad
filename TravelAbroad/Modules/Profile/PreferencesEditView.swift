//
//  PreferencesEditView.swift
//  TravelAbroad
//
//  Created for editing user travel preferences
//

import SwiftUI

struct PreferencesEditView: View {
    @StateObject private var viewModel = PreferencesEditViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Loading preferences...")
                            Spacer()
                        }
                        .padding()
                    }
                } else if let preferences = viewModel.preferences {
                    travelStyleSection(preferences)
                    activityPreferencesSection(preferences)
                    practicalPreferencesSection(preferences)
                    additionalPreferencesSection(preferences)
                } else {
                    Section {
                        HStack {
                            Spacer()
                            Text("No preferences found")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Travel Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.savePreferences()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isSaving {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack {
                                ProgressView()
                                Text("Saving...")
                                    .padding(.top, 8)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        )
                }
            }
        }
        .task {
            await viewModel.loadPreferences()
        }
    }
    
    private func travelStyleSection(_ preferences: UserPreferences) -> some View {
        Section("Travel Style") {
            Picker("Energy Level", selection: Binding(
                get: { viewModel.preferences?.travelStyle.energyLevel ?? .balanced },
                set: { viewModel.preferences?.travelStyle.energyLevel = $0 }
            )) {
                ForEach(TravelStylePreferences.EnergyLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            
            Picker("Social Preference", selection: Binding(
                get: { viewModel.preferences?.travelStyle.socialPreference ?? .flexible },
                set: { viewModel.preferences?.travelStyle.socialPreference = $0 }
            )) {
                ForEach(TravelStylePreferences.SocialPreference.allCases, id: \.self) { social in
                    Text(social.displayName).tag(social)
                }
            }
            
            Picker("Time Preference", selection: Binding(
                get: { viewModel.preferences?.travelStyle.timePreference ?? .flexible },
                set: { viewModel.preferences?.travelStyle.timePreference = $0 }
            )) {
                ForEach(TravelStylePreferences.TimePreference.allCases, id: \.self) { time in
                    Text(time.displayName).tag(time)
                }
            }
            
            Picker("Budget Range", selection: Binding(
                get: { viewModel.preferences?.travelStyle.budgetRange ?? .moderate },
                set: { viewModel.preferences?.travelStyle.budgetRange = $0 }
            )) {
                ForEach(TravelStylePreferences.BudgetRange.allCases, id: \.self) { budget in
                    Text(budget.displayName).tag(budget)
                }
            }
        }
    }
    
    private func activityPreferencesSection(_ preferences: UserPreferences) -> some View {
        Section("Activity Preferences") {
            ForEach(ActivityPreferences.ActivityType.allCases, id: \.self) { activity in
                HStack {
                    VStack(alignment: .leading) {
                        Text(activity.displayName)
                        Image(systemName: activity.icon)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker(activity.displayName, selection: Binding(
                        get: { viewModel.preferences?.activityPreferences.preferences[activity] ?? .likeIt },
                        set: { newValue in
                            viewModel.preferences?.activityPreferences.preferences[activity] = newValue
                        }
                    )) {
                        ForEach(ActivityPreferences.PreferenceLevel.allCases, id: \.self) { level in
                            Text(level.displayName)
                                .foregroundColor(Color(level.color))
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func practicalPreferencesSection(_ preferences: UserPreferences) -> some View {
        Section("Getting Around") {
            Picker("Walking Distance", selection: Binding(
                get: { viewModel.preferences?.practicalPreferences.maxWalkingDistance ?? .moderate },
                set: { viewModel.preferences?.practicalPreferences.maxWalkingDistance = $0 }
            )) {
                ForEach(PracticalPreferences.WalkingDistance.allCases, id: \.self) { distance in
                    Text(distance.displayName).tag(distance)
                }
            }
            
            Picker("Transportation", selection: Binding(
                get: { viewModel.preferences?.practicalPreferences.transportationPreference ?? .flexible },
                set: { viewModel.preferences?.practicalPreferences.transportationPreference = $0 }
            )) {
                ForEach(PracticalPreferences.TransportationPreference.allCases, id: \.self) { transport in
                    Text(transport.displayName).tag(transport)
                }
            }
            
            Picker("Accommodation", selection: Binding(
                get: { viewModel.preferences?.practicalPreferences.accommodationStyle ?? .flexible },
                set: { viewModel.preferences?.practicalPreferences.accommodationStyle = $0 }
            )) {
                ForEach(PracticalPreferences.AccommodationStyle.allCases, id: \.self) { accommodation in
                    Text(accommodation.displayName).tag(accommodation)
                }
            }
        }
    }
    
    private func additionalPreferencesSection(_ preferences: UserPreferences) -> some View {
        Section("Additional Preferences") {
            Picker("Planning Style", selection: Binding(
                get: { viewModel.preferences?.additionalPreferences.planningStyle ?? .structured },
                set: { viewModel.preferences?.additionalPreferences.planningStyle = $0 }
            )) {
                ForEach(AdditionalPreferences.PlanningStyle.allCases, id: \.self) { planning in
                    Text(planning.displayName).tag(planning)
                }
            }
            
            Picker("Risk Tolerance", selection: Binding(
                get: { viewModel.preferences?.additionalPreferences.riskTolerance ?? .moderate },
                set: { viewModel.preferences?.additionalPreferences.riskTolerance = $0 }
            )) {
                ForEach(AdditionalPreferences.RiskTolerance.allCases, id: \.self) { risk in
                    Text(risk.displayName).tag(risk)
                }
            }
            
            Picker("Cultural Immersion", selection: Binding(
                get: { viewModel.preferences?.additionalPreferences.culturalImmersion ?? .moderate },
                set: { viewModel.preferences?.additionalPreferences.culturalImmersion = $0 }
            )) {
                ForEach(AdditionalPreferences.CulturalImmersion.allCases, id: \.self) { cultural in
                    Text(cultural.displayName).tag(cultural)
                }
            }
            
            Picker("Crowd Tolerance", selection: Binding(
                get: { viewModel.preferences?.additionalPreferences.crowdTolerance ?? .moderate },
                set: { viewModel.preferences?.additionalPreferences.crowdTolerance = $0 }
            )) {
                ForEach(AdditionalPreferences.CrowdTolerance.allCases, id: \.self) { crowd in
                    Text(crowd.displayName).tag(crowd)
                }
            }
        }
    }
}

#Preview {
    PreferencesEditView()
}
