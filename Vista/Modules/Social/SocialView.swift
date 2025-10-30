//
//  SocialView.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/17/25.
//

import SwiftUI

struct SocialView: View {
    @State private var vm = SocialViewModel()

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

                        // Feed content
                        if vm.isLoading && vm.feedItems.isEmpty {
                            // Loading state
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading feed...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fontDesign(.rounded)
                            }
                            .padding(.vertical, 60)
                        } else if vm.feedItems.isEmpty {
                            // Empty state
                            emptyStateView
                        } else {
                            // Feed items
                            LazyVStack(spacing: 12) {
                                ForEach(vm.feedItems) { feedItem in
                                    FeedItemCard(
                                        feedItem: feedItem,
                                        destination: destinationView(for: feedItem)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 24)
                }
                .refreshable {
                    await vm.refreshFeed()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Following")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue, Color.teal]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        UserSearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
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
        .task {
            await vm.fetchUser()
            await vm.fetchActivityFeed()
        }
    }

    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("No Activity Yet")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.primary)

                Text("Follow travelers to see their city and spot ratings here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fontDesign(.rounded)
                    .padding(.horizontal, 40)
            }

            NavigationLink {
                UserSearchView()
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Find Travelers")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // Destination view for navigation
    @ViewBuilder
    private func destinationView(for feedItem: FeedItem) -> some View {
        switch feedItem.type {
        case .cityRating:
            if let cityId = feedItem.cityId,
               let cityName = feedItem.cityName,
               let imageUrl = feedItem.cityImageUrl
            {
                RecommendationsView(
                    cityId: cityId,
                    cityName: cityName,
                    imageUrl: imageUrl,
                    userRating: nil,
                    isBucketList: false,
                    onRatingUpdated: nil,
                    cityRating: feedItem.rating
                )
            }
        case .spotReview:
            if let recommendation = feedItem.toRecommendation() {
                CommentsView(recommendation: recommendation)
            }
        }
    }
}

#Preview {
    SocialView()
}
