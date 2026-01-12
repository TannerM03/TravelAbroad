//
//  AppleSignIn.swift
//  Vista
//
//  Sign In with Apple button component
//

import AuthenticationServices
import SwiftUI

struct AppleSignInButton: View {
    @Bindable var viewModel: AppleSignInViewModel
    @Binding var isAuthenticated: Bool
    @Binding var shouldShowOnboarding: Bool

    var body: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            Task {
                switch result {
                case let .success(authorization):
                    await viewModel.handleSignInWithApple(authorization: authorization)

                    // Update parent view bindings
                    if viewModel.isAuthenticated {
                        isAuthenticated = viewModel.isAuthenticated
                        shouldShowOnboarding = viewModel.shouldShowOnboarding
                    }

                case let .failure(error):
                    viewModel.handleSignInError(error)
                }
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(12)
    }
}
