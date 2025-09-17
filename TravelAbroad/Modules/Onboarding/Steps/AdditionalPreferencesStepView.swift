//
//  AdditionalPreferencesStepView.swift
//  TravelAbroad
//

import SwiftUI

struct AdditionalPreferencesStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                planningStyleSection
                riskToleranceSection
                culturalImmersionSection
                crowdToleranceSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Final Touches")
                .font(.title)
                .fontWeight(.bold)

            Text("A few more details to perfect your itineraries")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    private var planningStyleSection: some View {
        CompactPreferenceSection(
            title: "Planning Style",
            icon: "list.clipboard",
            options: AdditionalPreferences.PlanningStyle.allCases,
            selectedOption: vm.preferences.additionalPreferences.planningStyle,
            optionDisplayName: { $0.displayName }
        ) { option in
            vm.updatePlanningStyle(option)
        }
    }

    private var riskToleranceSection: some View {
        CompactPreferenceSection(
            title: "Adventure Level",
            icon: "mountain.2",
            options: AdditionalPreferences.RiskTolerance.allCases,
            selectedOption: vm.preferences.additionalPreferences.riskTolerance,
            optionDisplayName: { $0.displayName }
        ) { option in
            vm.updateRiskTolerance(option)
        }
    }

    private var culturalImmersionSection: some View {
        CompactPreferenceSection(
            title: "Cultural Experience",
            icon: "globe.americas",
            options: AdditionalPreferences.CulturalImmersion.allCases,
            selectedOption: vm.preferences.additionalPreferences.culturalImmersion,
            optionDisplayName: { $0.displayName }
        ) { option in
            vm.updateCulturalImmersion(option)
        }
    }

    private var crowdToleranceSection: some View {
        CompactPreferenceSection(
            title: "Crowd Preference",
            icon: "person.3",
            options: AdditionalPreferences.CrowdTolerance.allCases,
            selectedOption: vm.preferences.additionalPreferences.crowdTolerance,
            optionDisplayName: { $0.displayName }
        ) { option in
            vm.updateCrowdTolerance(option)
        }
    }
}

struct CompactPreferenceSection<T: Equatable>: View {
    let title: String
    let icon: String
    let options: [T]
    let selectedOption: T
    let optionDisplayName: (T) -> String
    let onSelection: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    CompactOptionButton(
                        title: optionDisplayName(option),
                        isSelected: selectedOption == option,
                        isFirst: index == 0,
                        isLast: index == options.count - 1
                    ) {
                        onSelection(option)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CompactOptionButton: View {
    let title: String
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(
                        cornerRadius: isFirst ? 8 : (isLast ? 8 : 0),
                        style: .continuous
                    )
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Alternative segmented control style for 3-option preferences
struct SegmentedPreferenceSection<T: Equatable & CaseIterable>: View where T.AllCases: RandomAccessCollection {
    let title: String
    let icon: String
    let selectedOption: T
    let optionDisplayName: (T) -> String
    let onSelection: (T) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Custom segmented control
            HStack(spacing: 0) {
                ForEach(Array(T.allCases.enumerated()), id: \.offset) { _, option in
                    Button(action: { onSelection(option) }) {
                        Text(optionDisplayName(option))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedOption == option ? .white : .accentColor)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Rectangle()
                                    .fill(selectedOption == option ? Color.accentColor : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdditionalPreferencesStepView(vm: OnboardingViewModel())
}
