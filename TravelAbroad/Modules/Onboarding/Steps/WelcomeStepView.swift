//
//  WelcomeStepView.swift
//  TravelAbroad
//

import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App icon or logo
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)

            VStack(spacing: 16) {
                Text("Welcome to TravelAbroad!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Let's personalize your travel experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                FeatureRow(
                    icon: "brain",
                    title: "Smart Itineraries",
                    description: "AI-powered recommendations based on your preferences"
                )

                FeatureRow(
                    icon: "map",
                    title: "Personalized Plans",
                    description: "Day-by-day itineraries tailored to your travel style"
                )

                FeatureRow(
                    icon: "heart",
                    title: "Your Preferences",
                    description: "Tell us what you love and we'll make it happen"
                )
            }
            .padding(.vertical, 20)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    WelcomeStepView()
}
