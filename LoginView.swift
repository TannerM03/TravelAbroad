//  LoginView.swift
//  TravelAbroad
//
//  Created as a login/signup screen for Supabase Auth.

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(isSignUp ? "Create Account" : "Login")
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                    SecureField("Password", text: $password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                }
                .padding(.horizontal)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: authAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .disabled(isLoading)

                Button(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .padding(.top)

                Spacer()
            }
            .padding()
        }
    }

    func authAction() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                if isSignUp {
                    let result = try await SupabaseManager.shared.supabase.auth.signUp(email: email, password: password)
                    if result.user != nil {
                        isAuthenticated = true
                    } else {
                        errorMessage = "Sign up failed. Check your email for confirmation."
                    }
                } else {
                    let session = try await SupabaseManager.shared.supabase.auth.signIn(email: email, password: password)
                    if session.user != nil {
                        isAuthenticated = true
                    } else {
                        errorMessage = "Login failed. Are your credentials correct?"
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
}
