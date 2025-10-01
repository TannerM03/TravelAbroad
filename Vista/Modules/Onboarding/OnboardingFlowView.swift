//
//  OnboardingFlowView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/10/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    @State private var vm = OnboardingViewModel()
    @Binding var shouldShowOnboarding: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemTeal).opacity(0.15),
                    Color(.systemIndigo).opacity(0.12),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator

                // Main content area
                TabView(selection: $vm.currentStep) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        stepContentView(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: vm.currentStep)

                // Navigation buttons
                if vm.currentStep != .names {
                    navigationButtons
                }
            }
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") {}
        } message: {
            Text(vm.errorMessage)
        }
    }

    @ViewBuilder
    private func stepContentView(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
        case .names:
            NamesView(onCompletion: vm.nextStep)
        case .travelStyle:
            TravelStyleStepView(vm: vm)
        case .activityPreferences:
            ActivityPreferencesStepView(vm: vm)
        case .walkingDistance:
            WalkingDistanceStepView(vm: vm)
        case .additionalPreferences:
            AdditionalPreferencesStepView(vm: vm)
        case .summary:
            SummaryStepView(vm: vm)
        }
    }

    private var progressIndicator: some View {
        VStack(spacing: 16) {
            HStack {
                Text(vm.progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            ProgressView(value: vm.currentStep.progress)
                .tint(.accentColor)
                .scaleEffect(y: 1.5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button
            Button(action: vm.previousStep) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.accentColor)
                .font(.headline)
            }
            .opacity(vm.canGoBack ? 1.0 : 0.0)
            .disabled(!vm.canGoBack)

            Spacer()

            // Next/Complete button
            Button(action: {
                if vm.isLastStep {
                    Task {
                        await vm.completeOnboarding()
                        if !vm.showError {
                            shouldShowOnboarding = false
                        }
                    }
                } else {
                    vm.nextStep()
                }
            }) {
                HStack {
                    if vm.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(vm.isLastStep ? "Complete Setup" : "Next")
                        if !vm.isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .font(.headline.bold())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(vm.canProceed() ? Color.accentColor : Color.gray.opacity(0.5))
                )
            }
            .disabled(!vm.canProceed() || vm.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

#Preview {
    OnboardingFlowView(shouldShowOnboarding: .constant(true))
}
