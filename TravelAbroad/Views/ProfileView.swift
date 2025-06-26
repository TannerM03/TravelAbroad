//
//  ProfileView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Supabase
import SwiftUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    // Need to make vm for getting real user data
    @StateObject var vm = ProfileViewModel()
    @State private var profileImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil

    @State private var user: User? = nil
    @State private var showLogoutDialog = false

    var email: String {
        user?.email ?? ""
    }

    var username: String {
        user?.userMetadata["username"] as? String ?? ""
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    HStack(alignment: .center) {
                        VStack(alignment: .center, spacing: 8) {
                            if let image = profileImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 150, height: 150)
                                    .overlay(Image(systemName: "person.fill").font(.largeTitle))
                            }
                            Text(email)
                        }
                    }
                }

                //Logout button
                Section {
                    Button(action: {
                        showLogoutDialog = true
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
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
            .navigationTitle(username)
        }
        .task {
            user = try? await SupabaseManager.shared.supabase.auth.session.user
        }
    }
}

#Preview {
    ProfileView(isAuthenticated: .constant(true))
}
