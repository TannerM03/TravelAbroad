//
//  ForgotPasswordView.swift
//  Vista
//
//  Password reset email request screen
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var vm = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemTeal).opacity(0.18), Color(.systemIndigo).opacity(0.14)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer(minLength: 60)

                VStack(spacing: 24) {
                    titleSection
                    descriptionSection
                    emailInputSection
                    messageSection
                    actionButtonSection
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
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var titleSection: some View {
        Text("Reset Password")
            .font(.largeTitle).bold()
            .padding(.top, 8)
    }

    private var descriptionSection: some View {
        Text("Enter your email address and we'll send you a link to reset your password")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var emailInputSection: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.accentColor)
            TextField("Email", text: $vm.email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .onChange(of: vm.email) { _, _ in
                    vm.clearMessages()
                }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))
        .padding(.horizontal, 8)
    }

    private var messageSection: some View {
        Group {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.callout.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            } else if let successMessage = vm.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.callout.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    private var actionButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await vm.sendResetEmail()
                }
            }) {
                HStack {
                    if vm.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    Text(vm.isLoading ? "Sending..." : "Send Reset Email")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(vm.isLoading || vm.email.isEmpty)
            .opacity((vm.isLoading || vm.email.isEmpty) ? 0.6 : 1.0)
            .padding(.horizontal, 8)

            Button(action: {
                dismiss()
            }) {
                Text("Back to Login")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
