//
//  SummaryStepView.swift
//  TravelAbroad
//

import SwiftUI

struct SummaryStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                preferenceSummarySection
                activityPreferencesSection
                callToActionSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("All Set!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your travel profile is ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var preferenceSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Travel Style")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                SummaryRow(
                    icon: "bolt.circle.fill",
                    title: "Energy Level",
                    value: vm.preferences.travelStyle.energyLevel.displayName
                )
                
                SummaryRow(
                    icon: "person.2.circle.fill",
                    title: "Group Size",
                    value: vm.preferences.travelStyle.socialPreference.displayName
                )
                
                SummaryRow(
                    icon: "clock.circle.fill",
                    title: "Schedule",
                    value: vm.preferences.travelStyle.timePreference.displayName
                )
                
                SummaryRow(
                    icon: "dollarsign.circle.fill",
                    title: "Budget",
                    value: vm.preferences.travelStyle.budgetRange.displayName
                )
                
                SummaryRow(
                    icon: "figure.walk.circle.fill",
                    title: "Walking Distance",
                    value: vm.preferences.practicalPreferences.maxWalkingDistance.displayName
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
    
    private var activityPreferencesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Activity Preferences")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 16) {
                if !vm.loveItActivities.isEmpty {
                    ActivitySummarySection(
                        title: "Love it!",
                        color: .green,
                        activities: vm.loveItActivities
                    )
                }
                
                if !vm.likeItActivities.isEmpty {
                    ActivitySummarySection(
                        title: "Like it",
                        color: .blue,
                        activities: vm.likeItActivities
                    )
                }
                
                if !vm.notMyFavActivities.isEmpty {
                    ActivitySummarySection(
                        title: "Not my fav",
                        color: .gray,
                        activities: vm.notMyFavActivities
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
    
    private var callToActionSection: some View {
        VStack(spacing: 16) {
            Text("🎯 Perfect! We'll use these preferences to create amazing itineraries just for you.")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                Text("What happens next:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("Your preferences will be saved securely")
                            .font(.caption)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("Our AI will learn your travel style")
                            .font(.caption)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text("You'll get personalized itineraries for every destination")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            )
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ActivitySummarySection: View {
    let title: String
    let color: Color
    let activities: [ActivityPreferences.ActivityType]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(activities.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.2))
                    )
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(activities, id: \.self) { activity in
                    HStack(spacing: 6) {
                        Image(systemName: activity.icon)
                            .font(.caption2)
                            .foregroundColor(color)
                            .frame(width: 12)
                        
                        Text(activity.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.15))
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    SummaryStepView(vm: OnboardingViewModel())
}
