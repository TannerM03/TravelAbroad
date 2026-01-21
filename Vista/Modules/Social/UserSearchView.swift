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
    @State private var searchTask: Task<Void, Never>?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

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

                        // Loading state
                        if vm.isLoading && vm.profiles.isEmpty {
                            ProgressView("Searching...")
                                .padding(.vertical, 40)
                        }
                        // Initial empty state
                        else if vm.profiles.isEmpty && searchText.isEmpty {
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
                                    Text("Search for Travelers")
                                        .font(.headline.weight(.semibold))
                                        .fontDesign(.rounded)
                                        .foregroundColor(.primary)

                                    Text("Search by name or username")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        }
                        // No results found
                        else if vm.profiles.isEmpty && !searchText.isEmpty && !vm.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "person.slash")
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

                                    Text("Try a different search term")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fontDesign(.rounded)
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        }
                        // Profiles grid
                        else if !vm.profiles.isEmpty {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(vm.profiles) { profile in
                                    NavigationLink {
                                        OtherProfileView(selectedUserId: profile.id.uuidString)
                                    } label: {
                                        ProfileCardView(profile: profile)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)

                            // Load More button
                            if vm.hasMoreUsers {
                                Button(action: {
                                    Task {
                                        await vm.loadMoreUsers()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        if vm.isLoadingMore {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        Text(vm.isLoadingMore ? "Loading..." : "Load More")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                }
                                .disabled(vm.isLoadingMore)
                                .padding(.horizontal, 20)
                            }
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
        }
        .onChange(of: searchText) { _, newValue in
            // Cancel previous search task
            searchTask?.cancel()

            // Update view model search query
            vm.searchQuery = newValue

            // Debounce: wait 400ms before searching
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                if !Task.isCancelled {
                    await vm.searchUsers(query: newValue)
                }
            }
        }
    }
}
