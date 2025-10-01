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
    @Bindable var vm: ProfileViewModel
    @StateObject private var bucketListViewModel = BucketListViewModel()
    @State private var travelHistoryViewModel = TravelHistoryViewModel()
    @State private var spotsViewModel = SpotsViewModel()
    @State private var profileImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var fromProfile = true
    @State private var selectedSegment = 0

    var body: some View {
        ZStack {
//            LinearGradient(
//                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
            NavigationStack {
                ScrollView {
                    VStack(spacing: 0) {
                        Section {
                            profileImageSection
                        }
                        .padding(.top, 10)

                        pickerSection
                            .padding(.top, 15)
                            .padding(.bottom, 25)

                        gridSection
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("\(vm.username)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView(isAuthenticated: $isAuthenticated, vm: vm)
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
        .onAppear {
            Task {
                try await vm.fetchFollowers()
                await vm.refreshTravelStats()
            }
        }
    }

    private var profileImageSection: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center, spacing: 12) {
                CircularProfileImage(imageState: vm.imageState)
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $vm.imageSelection,
                                     matching: .images,
                                     photoLibrary: .shared())
                        {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                HStack(spacing: 25) {
                    NavigationLink {
                        if let userId = vm.userId {
                            FollowListView(userId: userId, listType: .followers)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(vm.followerCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        if let userId = vm.userId {
                            FollowListView(userId: userId, listType: .following)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(vm.followingCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    VStack(spacing: 4) {
                        Text("\(vm.countriesVisited)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Countries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(vm.citiesVisited)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Cities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(vm.spotsReviewed)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Spots")
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
//        .padding(.vertical, 8)
    }

    private var pickerSection: some View {
        Picker("Content", selection: $selectedSegment) {
            Text("Cities").tag(0)
            Text("Spots").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var gridSection: some View {
        if selectedSegment == 0 {
            CitiesGridView(vm: travelHistoryViewModel)
        } else {
            SpotsGridView(vm: spotsViewModel)
        }
    }
}

#Preview {
    ProfileView(isAuthenticated: .constant(true), vm: ProfileViewModel())
}
