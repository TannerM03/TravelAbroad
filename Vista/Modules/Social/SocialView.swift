//
//  SocialView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/17/25.
//

import SwiftUI

struct SocialView: View {
    @State private var vm = SocialViewModel()
    @State private var isSearching = false
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
                profile.username.localizedCaseInsensitiveContains(searchText)
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
                    VStack(spacing: 24) {
                        // Header section
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Social")
                                        .font(.title.weight(.bold))
                                        .fontDesign(.rounded)
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    Text("Connect with fellow travelers")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fontDesign(.rounded)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Search bar (when active)
                        if isSearching {
                            HStack {
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

                                Button("Cancel") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isSearching = false
                                        searchText = ""
                                    }
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .fontWeight(.medium)
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Profiles grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredProfiles) { profile in
                                NavigationLink {
                                    OtherProfileView(selectedUserId: profile.id.uuidString)
                                } label: {
                                    ProfileCardView(profile: profile)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.3), value: filteredProfiles.count)

                        // Loading/Empty state
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
                        } else if vm.profiles.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                VStack(spacing: 8) {
                                    ProgressView("Loading Travelers")
                                        .font(.headline.weight(.semibold))
                                        .fontDesign(.rounded)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSearching.toggle()
                            if !isSearching {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .font(.body.weight(.medium))
                    }
                }
            }
        }
        .onAppear {
            Task {
                await vm.fetchUser()
                if let userId = vm.userId {
                    await vm.fetchProfiles(userId: userId)
                }
            }
        }
    }
}

#Preview {
    SocialView()
}
