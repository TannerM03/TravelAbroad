//
//  ProfileView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Supabase
import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    // Need to make vm for getting real user data
    @StateObject var vm = ProfileViewModel()
    @State private var profileImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var showLogoutDialog = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    HStack(alignment: .center) {
                        Spacer()
                        VStack(alignment: .center, spacing: 8) {
                            CircularProfileImage(imageState: vm.imageState)
                                .overlay(alignment: .bottomTrailing) {
                                    PhotosPicker(selection: $vm.imageSelection,
                                                 matching: .images,
                                                 photoLibrary: .shared()) {
                                        Image(systemName: "pencil.circle.fill")
                                            .symbolRenderingMode(.multicolor)
                                            .font(.system(size: 30))
                                            .foregroundStyle(Color.accentColor)
                                    }.buttonStyle(.borderless)
                                }
                            Text(vm.email)
                                .padding()
                        }
                        Spacer()
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
            .navigationTitle(vm.username)
        }
        .task {
            await vm.fetchUser()
        }
    }
}

#Preview {
    ProfileView(isAuthenticated: .constant(true))
}
