//
//  NamesView.swift
//  Vista
//
//  Created by Tanner Macpherson on 10/1/25.
//

import SwiftUI

struct NamesView: View {
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isPrePopulated: Bool = false
    let onCompletion: () -> Void

    enum Field {
        case username, firstName, lastName
    }

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                headerSection

                VStack(spacing: 20) {
                    usernameField
                    firstNameField
                    lastNameField
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                continueButton
                    .padding(.top, 15)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            loadAppleUserDataIfAvailable()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            if isPrePopulated {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Name imported from Apple")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Username *")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter username", text: $username)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("First Name *")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter first name", text: $firstName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var lastNameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Name")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter last name", text: $lastName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var continueButton: some View {
        Button {
            saveNamesAndContinue()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLoading ? Color.gray.opacity(0.5) : Color.blue)
                    .frame(height: 48)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                        .foregroundColor(.white)
                        .font(.headline.bold())
                }
            }
        }
        .disabled(isLoading)
        .padding(.horizontal, 4)
    }

    private var canContinue: Bool {
        true // Always allow button to be pressed
    }

    private func saveNamesAndContinue() {
        Task {
            errorMessage = nil

            // Validate fields before proceeding
            if username.isEmpty {
                errorMessage = "Please enter a username"
                return
            }

            if username.count < 4 {
                errorMessage = "Username must be at least 4 characters"
                return
            }

            if firstName.isEmpty {
                errorMessage = "Please enter your first name"
                return
            }

            isLoading = true

            do {
                // Check username availability
                let isAvailable = try await SupabaseManager.shared.isUsernameAvailable(username: username)
                if !isAvailable {
                    errorMessage = "This username is already taken"
                    isLoading = false
                    return
                }

                // Get current user ID
                let userId = try await SupabaseManager.shared.supabase.auth.user().id

                // Save all names to database
                try await SupabaseManager.shared.saveUserNames(userId: userId, username: username, firstName: firstName, lastName: lastName)

                isLoading = false
                onCompletion()

            } catch {
                errorMessage = "Failed to save information. Please try again."
                isLoading = false
                print("Error saving names: \(error)")
            }
        }
    }

    private func loadAppleUserDataIfAvailable() {
        let appleSignInVm = AppleSignInViewModel()
        let userData = appleSignInVm.getAppleUserData()

        if let givenName = userData.givenName, !givenName.isEmpty {
            firstName = givenName
            isPrePopulated = true
        }

        if let familyName = userData.familyName, !familyName.isEmpty {
            lastName = familyName
            isPrePopulated = true
        }

        if isPrePopulated {
            print("✅ Pre-populated name fields from Apple Sign In: \(firstName) \(lastName)")
        }
    }
}
