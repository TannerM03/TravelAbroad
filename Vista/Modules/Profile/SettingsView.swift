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

                    NavigationLink(destination: PreferencesEditView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Travel Preferences")
                        }
                    }
                }

                Section {
                    logoutSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
}

// #Preview {
//    SettingsView(isAuthenticated: true)
// }
