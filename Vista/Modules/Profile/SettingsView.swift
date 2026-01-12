//
//  SettingsView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/4/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isAuthenticated: Bool
    @Bindable var vm: ProfileViewModel
    @State private var showLogoutDialog = false
    @State private var showDeleteAccountDialog = false
    @State private var showDeleteAccountError = false
    @State private var deleteAccountErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    NavigationLink(destination: ProfileEditView(vm: vm)) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Profile")
                        }
                    }

//                    NavigationLink(destination: PreferencesEditView()) {
//                        HStack {
//                            Image(systemName: "slider.horizontal.3")
//                                .foregroundColor(.blue)
//                                .frame(width: 24)
//                            Text("Travel Preferences")
//                        }
//                    }
                }

                Section("Feed Preferences") {
                    HStack {
                        Image(systemName: "newspaper")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Default Feed")
                        Spacer()
                        Picker("", selection: $vm.feedDefault) {
                            Text("Popular").tag("popular")
                            Text("Following").tag("following")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: vm.feedDefault) { _, newValue in
                            Task {
                                if let userId = vm.userId {
                                    try await SupabaseManager.shared.updateFeedDefault(userId: userId, feedDefault: newValue)
                                }
                            }
                        }
                    }
                }

                Section {
                    logoutSection
                }

                Section {
                    Color.clear
                        .frame(height: 200)
                        .listRowBackground(Color.clear)
                }

                Section {
                    deleteAccountSection
                } header: {
                    Text("Danger Zone")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Account Deletion Error", isPresented: $showDeleteAccountError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteAccountErrorMessage)
            }
        }
    }

    private var logoutSection: some View {
        Button(action: {
            showLogoutDialog = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                    .frame(width: 24)
                Text("Log Out")
                    .foregroundColor(.red)
                Spacer()
            }
        }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutDialog, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                Task {
                    try await vm.logOut()
                    isAuthenticated = false
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var deleteAccountSection: some View {
        Button(action: {
            showDeleteAccountDialog = true
        }) {
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24)
                Text("Delete Account")
                    .foregroundColor(.red)
                Spacer()
            }
        }
        .confirmationDialog("Delete Account Permanently?", isPresented: $showDeleteAccountDialog, titleVisibility: .visible) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    do {
                        try await vm.deleteAccount()
                        isAuthenticated = false
                    } catch {
                        deleteAccountErrorMessage = "Failed to delete account: \(error.localizedDescription)"
                        showDeleteAccountError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data including reviews, ratings, and profile information will be permanently deleted.")
        }
    }
}

// #Preview {
//    SettingsView(isAuthenticated: true)
// }
