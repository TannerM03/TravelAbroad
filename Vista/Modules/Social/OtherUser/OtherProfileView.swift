//
//  OtherProfileView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/15/25.
//

import PhotosUI
import Supabase
import SwiftUI

struct OtherProfileView: View {
    let selectedUserId: String
    @State private var vm: OtherProfileViewModel
    @State private var travelHistoryViewModel: OtherUserTravelHistoryViewModel
    @State private var spotsViewModel: OtherUserSpotsViewModel
    @State private var profileImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var fromProfile = true
    @State private var selectedSegment = 0

    init(selectedUserId: String) {
        self.selectedUserId = selectedUserId
        vm = OtherProfileViewModel(userId: selectedUserId)
        travelHistoryViewModel = OtherUserTravelHistoryViewModel(userId: selectedUserId)
        spotsViewModel = OtherUserSpotsViewModel(userId: selectedUserId)
    }

    var body: some View {
        ZStack {
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 4) {
                            Text(vm.username)
                                .font(.headline)
                                .fontWeight(.bold)
                            if vm.isPopular {
                                Image(systemName: "crown.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.yellow)
                            }
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

                // Preload travel history data
                if let userId = vm.userId {
                    if travelHistoryViewModel.cities.isEmpty {
                        await travelHistoryViewModel.getCities(userId: userId, showLoading: true)
                    }

                    try? await vm.fetchFollowers()
                    try? await vm.fetchIsFollowing()
                }
            }
        }
    }

    private var profileImageSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image on the left
                CircularProfileImage(imageState: vm.imageState)
                    .overlay(alignment: .topTrailing) {
                        if vm.isPopular {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white, .blue)
                                .background(Circle().fill(.white))
                                .offset(x: -10, y: -5)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            Task {
                                try await vm.toggleFollow()
                            }
                        } label: {
                            Circle()
                                .fill(vm.isFollowing ? Color.green : Color.blue)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: vm.isFollowing ? "person.fill.checkmark" : "person.fill.badge.plus")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }

                // Followers/Following and Bio
                VStack(alignment: .center, spacing: 12) {
                    if vm.bio.isEmpty {
                        Spacer()
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

                    bioSection

                    if vm.bio.isEmpty {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)

            // Travel stats below
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
            OtherUserCitiesGridView(vm: travelHistoryViewModel)
        } else {
            OtherUserSpotsGridView(vm: spotsViewModel)
        }
    }

    private var bioSection: some View {
        Group {
            if !vm.bio.isEmpty {
                Text(vm.bio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
    }
}

// #Preview {
//    ProfileView(isAuthenticated: .constant(true), vm: ProfileViewModel())
// }
