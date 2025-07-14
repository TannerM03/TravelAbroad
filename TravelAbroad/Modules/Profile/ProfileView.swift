//
//  ProfileView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import PhotosUI
import Supabase
import SwiftUI

struct ProfileView: View {
    @Binding var isAuthenticated: Bool
    @ObservedObject var vm: ProfileViewModel
    @StateObject private var bucketListViewModel = BucketListViewModel()
    @StateObject private var travelHistoryViewModel = TravelHistoryViewModel()
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
                    Section {
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
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            if vm.user == nil {
                await vm.fetchUser()

                // Preload bucket list and travel history data
                if let userId = vm.userId {
                    await bucketListViewModel.fetchUser()
                    await travelHistoryViewModel.fetchUser()

                    if bucketListViewModel.cities.isEmpty {
                        await bucketListViewModel.getCities(userId: userId)
                    }
                    if travelHistoryViewModel.cities.isEmpty {
                        await travelHistoryViewModel.getCities(userId: userId, showLoading: true)
                    }
                }
            }
        }
    }

    private var profileImageSection: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: 12) {
                Text("@\(vm.username)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)

                CircularProfileImage(imageState: vm.imageState)
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $vm.imageSelection,
                                     matching: .images,
                                     photoLibrary: .shared())
                        {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 30))
                                .foregroundStyle(Color.accentColor)
                        }.buttonStyle(.borderless)
                    }

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("\(vm.citiesVisited)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Cities Visited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(vm.recsSubmitted)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Reviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var travelHistorySection: some View {
        NavigationLink {
            TravelHistoryView(vm: travelHistoryViewModel)
        } label: {
            Text("Travel History")
        }
    }

    private var bucketListSection: some View {
        NavigationLink {
            BucketListView(vm: bucketListViewModel)
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
    ProfileView(isAuthenticated: .constant(true), vm: ProfileViewModel())
}
