//  LoginView.swift
//  TravelAbroad
//
//  Created as a login/signup screen for Supabase Auth.

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginViewModel()
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            VStack() {
                Text(vm.isSignUp ? "Create Account" : "Login")
                    .font(.largeTitle)
                    .bold()
                
                VStack() {
                    TextField("Email", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                    SecureField("Password", text: $vm.password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                }
                .padding(.horizontal)
                
                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task { await authAction() }
                } label: {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Text(vm.isSignUp ? "Sign Up" : "Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .disabled(vm.isLoading)
                
                Button(vm.isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up") {
                    vm.isSignUp.toggle()
                    vm.errorMessage = nil
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
    }
    
    func authAction() async {
        vm.errorMessage = nil
        vm.isLoading = true
        do {
            if vm.isSignUp {
                try await SupabaseManager.shared.supabase.auth.signUp(email: vm.email, password: vm.password)
            } else {
                try await SupabaseManager.shared.supabase.auth.signIn(email: vm.email, password: vm.password)
            }
            isAuthenticated = true
        } catch {
            vm.errorMessage = error.localizedDescription
        }
        vm.isLoading = false
    }
}
//
//#Preview {
//    LoginView()
//}
