//  LoginView.swift
//  TravelAbroad
//
//  Created as a login/signup screen for Supabase Auth.

import Foundation
import SwiftUI

struct LoginView: View {
    @State private var vm = LoginViewModel()
    @State private var profileVm = ProfileViewModel()
    @State private var appleSignInVm = AppleSignInViewModel()
    @Binding var isAuthenticated: Bool
    @Binding var shouldShowOnboarding: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemTeal).opacity(0.18), Color(.systemIndigo).opacity(0.14)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 60)

                VStack(spacing: 24) {
                    titleSection
                    inputFieldsSection
                    errorMessageSection
                    actionButtonSection

                    dividerSection
                    appleSignInSection

                    toggleModeSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.thinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                Spacer()
            }
        }
        .alert("Check Your Email", isPresented: $vm.showEmailConfirmationDialog) {
            Button("OK") {
                vm.showEmailConfirmationDialog = false
            }
        } message: {
            Text("We've sent a confirmation link to \(vm.loginCredential). Please check your email on your phone and tap the link to complete your account setup.")
        }
    }

    private var titleSection: some View {
        Text(vm.isSignUp ? "Create Account" : "Login")
            .font(.largeTitle).bold()
            .padding(.top, 8)
    }

    private var inputFieldsSection: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.accentColor)
                TextField(vm.isSignUp ? "Email" : "Email or username", text: $vm.loginCredential)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))

            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.accentColor)
                SecureField("Password", text: $vm.password)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))
        }
        .padding(.horizontal, 8)
    }

    private var errorMessageSection: some View {
        Group {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage.localizedLowercase)
                    .foregroundColor(.red)
                    .font(.callout.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    private var actionButtonSection: some View {
        Button {
            Task {
                let wasSignUp = vm.isSignUp
                isAuthenticated = await vm.authAction()
                let isDoneOnboarding = await vm.hasCompletedOnboarding()

                // Only trigger onboarding for new sign-ups
                if wasSignUp && isAuthenticated || !isDoneOnboarding && isAuthenticated {
                    shouldShowOnboarding = true
                }

                await profileVm.fetchUser()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(vm.loginCredential.isEmpty || vm.password.isEmpty || vm.isLoading ? Color.gray.opacity(0.5) : Color.accentColor)
                    .frame(height: 48)
                Text(vm.isSignUp ? "Sign Up" : "Login")
                    .foregroundColor(.white)
                    .font(.headline.bold())
            }
        }
        .disabled(vm.loginCredential == "" || vm.password == "" || vm.isLoading)
        .padding(.horizontal, 4)
    }

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            Text("or")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    private var appleSignInSection: some View {
        VStack(spacing: 12) {
            AppleSignInButton(
                viewModel: appleSignInVm,
                isAuthenticated: $isAuthenticated,
                shouldShowOnboarding: $shouldShowOnboarding
            )
            .padding(.horizontal, 4)

            if let errorMessage = appleSignInVm.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var toggleModeSection: some View {
        Button(action: {
            vm.isSignUp.toggle()
            vm.errorMessage = nil
        }) {
            Text(vm.isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                .font(.subheadline)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 6)
    }
}

// #Preview("Login Mode") {
//    LoginView(isAuthenticated: .constant(false), shouldShowOnboarding: .constant(false))
// }
