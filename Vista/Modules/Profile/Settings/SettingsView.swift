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
    @State private var blockedUsers: [(id: UUID, username: String)] = []
    @State private var showUnblockConfirmation = false
    @State private var userToUnblock: (id: UUID, username: String)?

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
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("Default Feed Type")
                            .font(.footnote)

                        Spacer()
                        Picker("", selection: $vm.feedDefault) {
                            Text("Popular Creators").tag("popular")
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
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("Show Own Posts in Following Feed")
                            .font(.footnote)
                        Spacer()
                        Picker("", selection: $vm.showOwnPostsInFollowing) {
                            Text("Yes").tag(true)
                            Text("No").tag(false)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: vm.showOwnPostsInFollowing) { _, newValue in
                            Task {
                                if let userId = vm.userId {
                                    try await SupabaseManager.shared.updateFollowingFeedPreference(userId: userId, followingFeedPref: newValue)
                                }
                            }
                        }
                    }
                }

                if vm.isAmbassador {
                    ambassadorSection
                }

                Section("Popular Creators") {
                    NavigationLink(destination: PopularCreatorView(profileVm: vm)) {
                        HStack {
                            Image(systemName: "star.circle")
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24)
                            Text("Become a Popular Creator")
                        }
                    }
                }

                Section("Safety & Privacy") {
                    NavigationLink(destination: BlockedUsersListView(blockedUsers: $blockedUsers)) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Blocked Users")
                            Spacer()
                            if !blockedUsers.isEmpty {
                                Text("\(blockedUsers.count)")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                Section("More...") {
                    NavigationLink(destination: HelpAndSupportView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Help & Support")
                        }
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    logoutSection
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
            .task {
                await loadBlockedUsers()
            }
        }
    }

    private func loadBlockedUsers() async {
        do {
            let blockedIds = try await SupabaseManager.shared.getBlockedUsers()

            // Fetch usernames for blocked users
            var users: [(id: UUID, username: String)] = []
            for blockedId in blockedIds {
                if let username = try? await fetchUsername(for: blockedId) {
                    users.append((id: blockedId, username: username))
                }
            }

            await MainActor.run {
                blockedUsers = users
            }
        } catch {
            print("Error loading blocked users: \(error)")
        }
    }

    private func fetchUsername(for userId: UUID) async throws -> String {
        struct UserProfile: Codable {
            let username: String
        }

        let profiles: [UserProfile] = try await SupabaseManager.shared.supabase
            .from("profiles")
            .select("username")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        return profiles.first?.username ?? "Unknown User"
    }

    private var ambassadorSection: some View {
        Section("Ambassador Program") {
            if let code = vm.referralCode {
                HStack {
                    Image(systemName: "tag.circle")
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24)
                    Text("Your Code")
                    Spacer()
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Image(systemName: "tag.circle")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("No referral code assigned yet")
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.green)
                    .frame(width: 24)
                Text("Referrals Completed")
                Spacer()
                Text("\(vm.referralCount)")
                    .foregroundColor(.secondary)
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

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

// #Preview {
//    SettingsView(isAuthenticated: true)
// }
