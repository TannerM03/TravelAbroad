//
//  WalkingDistanceStepView.swift
//  TravelAbroad
//

import SwiftUI

struct WalkingDistanceStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                walkingDistanceSection
                transportationSection
                accommodationSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Getting Around")
                .font(.title)
                .fontWeight(.bold)

            Text("Help us plan realistic itineraries for you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    private var walkingDistanceSection: some View {
        PreferenceSection(
            title: "Walking Distance",
            subtitle: "How far are you comfortable walking between activities?",
            icon: "figure.walk.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(PracticalPreferences.WalkingDistance.allCases, id: \.self) { distance in
                    WalkingDistanceCard(
                        distance: distance,
                        isSelected: vm.preferences.practicalPreferences.maxWalkingDistance == distance
                    ) {
                        vm.updateWalkingDistance(distance)
                    }
                }
            }
        }
    }

    private var transportationSection: some View {
        PreferenceSection(
            title: "Transportation",
            subtitle: "How do you prefer to get around cities?",
            icon: "car.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(PracticalPreferences.TransportationPreference.allCases, id: \.self) { transport in
                    SelectionCard(
                        title: transport.displayName,
                        subtitle: nil,
                        isSelected: vm.preferences.practicalPreferences.transportationPreference == transport
                    ) {
                        vm.updateTransportationPreference(transport)
                    }
                }
            }
        }
    }

    private var accommodationSection: some View {
        PreferenceSection(
            title: "Accommodation Style",
            subtitle: "This helps us recommend nearby activities",
            icon: "bed.double.circle.fill"
        ) {
            VStack(spacing: 12) {
                ForEach(PracticalPreferences.AccommodationStyle.allCases, id: \.self) { accommodation in
                    SelectionCard(
                        title: accommodation.displayName,
                        subtitle: nil,
                        isSelected: vm.preferences.practicalPreferences.accommodationStyle == accommodation
                    ) {
                        vm.updateAccommodationStyle(accommodation)
                    }
                }
            }
        }
    }
}

struct WalkingDistanceCard: View {
    let distance: PracticalPreferences.WalkingDistance
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(distance.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(walkingTimeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }

                // Visual walking indicator
                HStack(spacing: 4) {
                    ForEach(0 ..< walkingIndicatorCount, id: \.self) { _ in
                        Image(systemName: "figure.walk")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                    }

                    if walkingIndicatorCount < 5 {
                        ForEach(walkingIndicatorCount ..< 5, id: \.self) { _ in
                            Image(systemName: "figure.walk")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                    }

                    Spacer()

                    Text("\(String(format: "%.1f", distance.maxDistanceInMiles)) mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? .accentColor : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var walkingIndicatorCount: Int {
        switch distance {
        case .short: return 2
        case .moderate: return 3
        case .long: return 4
        }
    }

    private var walkingTimeDescription: String {
        let minutes = Int(distance.maxDistanceInMiles * 20) // Assuming 20 minutes per mile
        return "~\(minutes) min walk"
    }
}

#Preview {
    WalkingDistanceStepView(vm: OnboardingViewModel())
}
