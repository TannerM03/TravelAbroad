//
//  TravelStyleStepView.swift
//  TravelAbroad
//

import SwiftUI

struct TravelStyleStepView: View {
    @ObservedObject var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                energyLevelSection
                socialPreferenceSection
                timePreferenceSection
                budgetRangeSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Your Travel Style")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Help us understand how you like to explore")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var energyLevelSection: some View {
        PreferenceSection(
            title: "Energy Level",
            subtitle: "How packed do you like your days?",
            icon: "bolt.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(TravelStylePreferences.EnergyLevel.allCases, id: \.self) { level in
                    SelectionCard(
                        title: level.displayName,
                        subtitle: level.description,
                        isSelected: vm.preferences.travelStyle.energyLevel == level
                    ) {
                        vm.updateEnergyLevel(level)
                    }
                }
            }
        }
    }
    
    private var socialPreferenceSection: some View {
        PreferenceSection(
            title: "Group Size",
            subtitle: "What's your ideal travel group?",
            icon: "person.2.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(TravelStylePreferences.SocialPreference.allCases, id: \.self) { social in
                    SelectionCard(
                        title: social.displayName,
                        subtitle: nil,
                        isSelected: vm.preferences.travelStyle.socialPreference == social
                    ) {
                        vm.updateSocialPreference(social)
                    }
                }
            }
        }
    }
    
    private var timePreferenceSection: some View {
        PreferenceSection(
            title: "Daily Schedule",
            subtitle: "When are you most active?",
            icon: "clock.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(TravelStylePreferences.TimePreference.allCases, id: \.self) { time in
                    SelectionCard(
                        title: time.displayName,
                        subtitle: nil,
                        isSelected: vm.preferences.travelStyle.timePreference == time
                    ) {
                        vm.updateTimePreference(time)
                    }
                }
            }
        }
    }
    
    private var budgetRangeSection: some View {
        PreferenceSection(
            title: "Budget Range",
            subtitle: "What's comfortable for activities & dining?",
            icon: "dollarsign.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(TravelStylePreferences.BudgetRange.allCases, id: \.self) { budget in
                    SelectionCard(
                        title: budget.displayName,
                        subtitle: nil,
                        isSelected: vm.preferences.travelStyle.budgetRange == budget,
                        accentColor: budget == .budget ? .green : .accentColor
                    ) {
                        vm.updateBudgetRange(budget)
                    }
                }
            }
        }
    }
}

struct PreferenceSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
        }
        .padding(.vertical, 8)
    }
}

struct SelectionCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        accentColor: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? accentColor : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? accentColor : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TravelStyleStepView(vm: OnboardingViewModel())
}