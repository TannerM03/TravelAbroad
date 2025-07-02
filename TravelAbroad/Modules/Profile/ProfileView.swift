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
    @State private var fromProfile = true

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemTeal).opacity(0.18), Color(.systemIndigo).opacity(0.14)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            NavigationStack {
                Form {
                    Section(header: Text("Profile")) {
                        profileImageSection
                    }
                    Section {
                        travelHistorySection
                    }
                    Section {
                        bucketListSection
                    }
                    Section {
                        logoutSection
                    }
                }
                .navigationTitle(vm.username)
            }
        }
        .task {
            await vm.fetchUser()
        }
    }
    
    private var profileImageSection: some View {
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
    
    private var travelHistorySection: some View {
                NavigationLink {
                    TravelHistoryView()
                } label: {
                    Text("Travel History")
                }
    }
    
    private var bucketListSection: some View {
        NavigationLink {
            BucketListView()
        } label: {
            Text("Bucket List")
        }
    }
    
    private var logoutSection: some View {
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

#Preview {
    ProfileView(isAuthenticated: .constant(true))
}
