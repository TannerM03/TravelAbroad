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

        do {
            feedItems = try await SupabaseManager.shared.fetchFollowingActivityFeed(userId: userId)
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

        do {
            popularFeedItems = try await SupabaseManager.shared.fetchPopularActivityFeed()
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
}
