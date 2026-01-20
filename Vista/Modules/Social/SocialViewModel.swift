//
//  SocialViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/17/25.
//

import Foundation
import Observation
import Supabase
import SwiftUI

@MainActor
@Observable
class SocialViewModel {
    var feedItems: [FeedItem] = []
    var popularFeedItems: [FeedItem] = []
    var userId: UUID?
    var isLoading: Bool = false
    var hasError: Bool = false
    var errorMessage: String = ""

    // Pagination state for following feed
    var isLoadingMoreFollowing = false
    var hasMoreFollowing = true
    var currentFollowingPage = 0
    let pageSize = 30

    // Pagination state for popular feed
    var isLoadingMorePopular = false
    var hasMorePopular = true
    var currentPopularPage = 0

    func fetchUser() async {
        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user.id
        } catch {
            print("Failed to fetch user: \(error)")
            hasError = true
            errorMessage = "Failed to load user data"
        }
    }

    func fetchActivityFeed() async {
        guard let userId = userId else {
            print("No user ID available")
            return
        }

        isLoading = true
        hasError = false
        currentFollowingPage = 0
        hasMoreFollowing = true

        do {
            feedItems = try await SupabaseManager.shared.fetchFollowingActivityFeed(
                userId: userId,
                limit: pageSize,
                offset: 0
            )
            if feedItems.count < pageSize {
                hasMoreFollowing = false
            }
        } catch {
            print("error fetching activity feed in vm: \(error.localizedDescription)")
            hasError = true
            errorMessage = "Failed to load feed"
        }

        isLoading = false
    }

    func fetchPopularFeed() async {
        isLoading = true
        hasError = false
        currentPopularPage = 0
        hasMorePopular = true

        do {
            popularFeedItems = try await SupabaseManager.shared.fetchPopularActivityFeed(
                limit: pageSize,
                offset: 0
            )
            if popularFeedItems.count < pageSize {
                hasMorePopular = false
            }
        } catch {
            print("error fetch popular activity feed in vm: \(error.localizedDescription)")
            hasError = true
            errorMessage = "failed to load popular feed"
        }

        isLoading = false
    }

    func refreshFeed() async {
        await fetchActivityFeed()
    }

    func loadMoreFollowingFeed() async {
        guard let userId = userId else {
            print("No user ID available")
            return
        }
        guard !isLoadingMoreFollowing, hasMoreFollowing else { return }

        isLoadingMoreFollowing = true
        currentFollowingPage += 1

        do {
            let newItems = try await SupabaseManager.shared.fetchFollowingActivityFeed(
                userId: userId,
                limit: pageSize,
                offset: currentFollowingPage * pageSize
            )
            feedItems.append(contentsOf: newItems)
            if newItems.count < pageSize {
                hasMoreFollowing = false
            }
        } catch {
            print("error loading more following feed: \(error.localizedDescription)")
            hasError = true
            errorMessage = "Failed to load more items"
        }

        isLoadingMoreFollowing = false
    }

    func loadMorePopularFeed() async {
        guard !isLoadingMorePopular, hasMorePopular else { return }

        isLoadingMorePopular = true
        currentPopularPage += 1

        do {
            let newItems = try await SupabaseManager.shared.fetchPopularActivityFeed(
                limit: pageSize,
                offset: currentPopularPage * pageSize
            )
            popularFeedItems.append(contentsOf: newItems)
            if newItems.count < pageSize {
                hasMorePopular = false
            }
        } catch {
            print("error loading more popular feed: \(error.localizedDescription)")
            hasError = true
            errorMessage = "Failed to load more items"
        }

        isLoadingMorePopular = false
    }
}
