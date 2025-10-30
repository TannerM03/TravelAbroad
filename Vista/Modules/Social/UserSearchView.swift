//
//  UserSearchView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 10/13/25
//

import SwiftUI

struct UserSearchView: View {
    @State private var vm = UserSearchViewModel()
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var filteredProfiles: [OtherProfile] {
        if searchText.isEmpty {
            return vm.profiles
        } else {
            return vm.profiles.filter { profile in
                profile.username?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)

                            TextField("Search travelers...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Profiles grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredProfiles) { profile in
                                NavigationLink {
                                    OtherProfileView(selectedUserId: profile.id.uuidString)
                                } label: {
                                    ProfileCardView(profile: profile)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Empty state
                        if filteredProfiles.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                VStack(spacing: 8) {
                                    Text("No travelers found")
                                        .font(.headline.weight(.semibold))
                                        .fontDesign(.rounded)
                                        .foregroundColor(.primary)

                                    Text("Try adjusting your search terms")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        } else if vm.profiles.isEmpty && vm.isLoading {
                            ProgressView("Loading travelers...")
                                .padding(.vertical, 40)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Travelers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await vm.fetchUser()
            if let userId = vm.userId {
                await vm.fetchProfiles(userId: userId)
            }
        }
    }
}
