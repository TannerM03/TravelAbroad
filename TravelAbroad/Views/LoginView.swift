//  LoginView.swift
//  TravelAbroad
//
//  Created as a login/signup screen for Supabase Auth.

import SwiftUI
import Foundation

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemTeal).opacity(0.18), Color(.systemIndigo).opacity(0.14)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 60)
                
                VStack(spacing: 24) {
                    // Title
                    Text(vm.isSignUp ? "Create Account" : "Login")
                        .font(.largeTitle).bold()
                        .padding(.top, 8)

                    VStack(spacing: 18) {
                        // Email field
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.accentColor)
                            TextField("Email", text: $vm.email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))

                        // Username field (for sign up)
                        if vm.isSignUp {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.accentColor)
                                TextField("Username (minimum of 4 characters)", text: $vm.username)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))
                        }

                        // Password field
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.accentColor)
                            SecureField("Password", text: $vm.password)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))
                    }
                    .padding(.horizontal, 8)

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage.localizedLowercase)
                            .foregroundColor(.red)
                            .font(.callout.bold())
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }

                    // Login/Sign up button
                    Button {
                        Task { isAuthenticated = await vm.authAction() }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.email.isEmpty || vm.password.isEmpty || vm.isLoading ? Color.gray.opacity(0.5) : Color.accentColor)
                                .frame(height: 48)
                            Text(vm.isSignUp ? "Sign Up" : "Login")
                                .foregroundColor(.white)
                                .font(.headline.bold())
                        }
                    }
                    .disabled(vm.email == "" || vm.password == "" || vm.isLoading || (vm.username.count < 4 && vm.isSignUp))
                    .padding(.horizontal, 4)

                    // Toggle between login/signup
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
    }
}

#Preview("Login Mode") {
    LoginView(isAuthenticated: .constant(false))
}
