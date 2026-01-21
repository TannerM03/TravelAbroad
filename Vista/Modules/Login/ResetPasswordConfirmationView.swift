//
//  ResetPasswordConfirmationView.swift
//  Vista
//
//  Password reset confirmation screen (after email link click)
//

import SwiftUI

struct ResetPasswordConfirmationView: View {
    @State private var vm = ResetPasswordConfirmationViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var showPasswordReset: Bool
    @Binding var passwordResetSuccess: Bool

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
                    passwordFieldsSection
                    requirementsSection
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
        .navigationTitle("Create New Password")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.passwordUpdatedSuccessfully) { _, success in
            if success {
                // Password updated successfully, return to login screen
                // Small delay to show success message
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await MainActor.run {
                        passwordResetSuccess = true
                        showPasswordReset = false
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        Text("Create New Password")
            .font(.largeTitle).bold()
            .padding(.top, 8)
    }

    private var descriptionSection: some View {
        Text("Enter your new password below")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var passwordFieldsSection: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.accentColor)
                SecureField("New Password", text: $vm.newPassword)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.accentColor)
                SecureField("Confirm Password", text: $vm.confirmPassword)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.24), lineWidth: 1))
        }
        .padding(.horizontal, 8)
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password must contain:")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Image(systemName: vm.newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(vm.newPassword.count >= 8 ? .green : .secondary)
                    .font(.caption)
                Text("At least 8 characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: vm.newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(vm.newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil ? .green : .secondary)
                    .font(.caption)
                Text("1 uppercase letter")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: vm.newPassword.rangeOfCharacter(from: .decimalDigits) != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(vm.newPassword.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .secondary)
                    .font(.caption)
                Text("1 number")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            } else if vm.passwordUpdatedSuccessfully {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Password updated successfully!")
                        .foregroundColor(.green)
                        .font(.callout.bold())
                }
                .padding(.top, 2)
            }
        }
    }

    private var actionButtonSection: some View {
        Button(action: {
            Task {
                await vm.updatePassword()
            }
        }) {
            HStack {
                if vm.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text(vm.isLoading ? "Updating..." : "Update Password")
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
        .disabled(vm.isLoading || vm.newPassword.isEmpty || vm.confirmPassword.isEmpty)
        .opacity((vm.isLoading || vm.newPassword.isEmpty || vm.confirmPassword.isEmpty) ? 0.6 : 1.0)
        .padding(.horizontal, 8)
    }
}

#Preview {
    NavigationStack {
        ResetPasswordConfirmationView(showPasswordReset: .constant(true), passwordResetSuccess: .constant(false))
    }
}
