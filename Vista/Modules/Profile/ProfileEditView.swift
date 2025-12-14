//
//  ProfileEditView.swift
//  Vista
//
//  Created by Tanner Macpherson on 9/28/25.
//

import SwiftUI

struct ProfileEditView: View {
    @Bindable var vm: ProfileViewModel
    @State private var newUsername: String = ""
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss

    enum Field {
        case username, firstName, lastName
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeaderSection
                profileFieldsSection

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .onAppear {
            newUsername = vm.username
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05), Color.clear]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await vm.makeProfileChanges(newUsername: newUsername)
                    }
                    dismiss()
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
        }
    }

    private var profileHeaderSection: some View {
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

            Text("Edit Your Profile")
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
        }
        .padding(.bottom, 8)
    }

    private var profileFieldsSection: some View {
        VStack {
            usernameField
            firstNameField
            lastNameField
        }
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Username")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter username", text: $newUsername)
                .focused($focusedField, equals: .username)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .onSubmit {
                    focusedField = .firstName
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("First Name")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter first name", text: $vm.firstName)
                .focused($focusedField, equals: .firstName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .onSubmit {
                    focusedField = .lastName
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var lastNameField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Name")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Enter last name", text: $vm.lastName)
                .focused($focusedField, equals: .lastName)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .onSubmit {
                    focusedField = nil
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email")
                .font(.headline)
                .fontWeight(.semibold)

            HStack {
                Text(vm.user?.email ?? "email")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                Spacer()

                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .padding(.trailing, 16)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Text("Email cannot be changed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
