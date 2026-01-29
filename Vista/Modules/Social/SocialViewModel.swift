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
            let fetchedItems = try await SupabaseManager.shared.fetchFollowingActivityFeed(
                userId: userId,
                limit: pageSize,
                offset: 0
            )

            // Filter out blocked users from feed
            feedItems = filterBlockedUsers(from: fetchedItems)

            if fetchedItems.count < pageSize {
                hasMoreFollowing = false
            }
        } catch {
            print("❌ Error fetching following feed: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .keyNotFound(key, context):
                    print("❌ Missing key: \(key.stringValue), codingPath: \(context.codingPath)")
                case let .typeMismatch(type, context):
                    print("❌ Type mismatch for type: \(type), codingPath: \(context.codingPath)")
                case let .valueNotFound(type, context):
                    print("❌ Value not found for type: \(type), codingPath: \(context.codingPath)")
                case let .dataCorrupted(context):
                    print("❌ Data corrupted: \(context)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
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
            let fetchedItems = try await SupabaseManager.shared.fetchPopularActivityFeed(
                limit: pageSize,
                offset: 0
            )

            // Filter out blocked users from feed
            popularFeedItems = filterBlockedUsers(from: fetchedItems)

            if fetchedItems.count < pageSize {
                hasMorePopular = false
            }
        } catch {
            print("❌ Error fetching popular feed: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .keyNotFound(key, context):
                    print("❌ Missing key: \(key.stringValue), codingPath: \(context.codingPath)")
                case let .typeMismatch(type, context):
                    print("❌ Type mismatch for type: \(type), codingPath: \(context.codingPath)")
                case let .valueNotFound(type, context):
                    print("❌ Value not found for type: \(type), codingPath: \(context.codingPath)")
                case let .dataCorrupted(context):
                    print("❌ Data corrupted: \(context)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
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

            // Filter out blocked users before appending
            let filteredItems = filterBlockedUsers(from: newItems)
            feedItems.append(contentsOf: filteredItems)

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

            // Filter out blocked users before appending
            let filteredItems = filterBlockedUsers(from: newItems)
            popularFeedItems.append(contentsOf: filteredItems)

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

    // MARK: - Safety & Filtering

    private func filterBlockedUsers(from items: [FeedItem]) -> [FeedItem] {
        return items.filter { item in
            // Keep item if user is NOT blocked
            !BlockListManager.shared.isUserBlocked(item.userId)
        }
    }
}
