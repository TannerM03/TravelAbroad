//
//  OtherProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/15/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class OtherProfileViewModel {
    var username: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var bio: String = ""
    var user: User?
    var profileImageURL: String?
    var userId: UUID?
    var citiesVisited: Int = 0
    var spotsReviewed: Int = 0
    var countriesVisited: Int = 0
    var followerCount: Int = 0
    var followingCount: Int = 0
    var isFollowing: Bool = false
    var isPopular: Bool = false
    var isSelf: Bool = false

    init(userId: String) {
        self.userId = UUID(uuidString: userId) ?? nil
    }

    func fetchUser() async {
        do {
            if let userId = userId {
                // Check if this profile is the current user's own profile
                let currentUserId = try await SupabaseManager.shared.supabase.auth.user().id
                isSelf = (userId == currentUserId)

                // Fetch all user data in parallel
                async let namesResult = SupabaseManager.shared.fetchUsernameAndNames(userId: userId)
                async let bioResult = SupabaseManager.shared.fetchUserBio(userId: userId)
                async let profilePicResult = SupabaseManager.shared.fetchProfilePic(userId: userId)
                async let isPopularResult = SupabaseManager.shared.fetchIsPopular(userId: userId)
                async let travelStatsResult = SupabaseManager.shared.fetchTravelStats(userId: userId)

                // Await all results together
                let (names, fetchedBio, fetchedProfilePicURL, fetchedIsPopular, travelStats) = try await (
                    namesResult, bioResult, profilePicResult, isPopularResult, travelStatsResult
                )

                // Update properties
                username = names[0]
                firstName = names[1]
                lastName = names[2]
                bio = fetchedBio
                profileImageURL = fetchedProfilePicURL
                isPopular = fetchedIsPopular
                countriesVisited = travelStats.countriesVisited
                citiesVisited = travelStats.citiesVisited
                spotsReviewed = travelStats.spotsVisited

            } else {
                print("userId didn't work yet")
            }

        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func fetchFollowers() async throws {
        Task {
            do {
                if let id = userId {
                    let response = try await SupabaseManager.shared.fetchFollowerCount(userId: id)
                    followerCount = response.0
                    followingCount = response.1
                } else {
                    print("id not fetched")
                }
            } catch {
                print("error fetching follow count: \(error.localizedDescription)")
            }
        }
    }

    func fetchIsFollowing() async throws {
        Task {
            do {
                guard let otherUserId = userId,
                      let currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id
                else {
                    return
                }
                isFollowing = try await SupabaseManager.shared.fetchIsFollowing(curUserId: currentUserId, otherUserId: otherUserId)
            } catch {
                print("error fetching follow status: \(error.localizedDescription)")
            }
        }
    }

    func toggleFollow() async throws {
        guard let otherUserId = userId,
              let currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id
        else {
            return
        }

        do {
            if isFollowing {
                print("unfollowing user")
                try await SupabaseManager.shared.unfollowUser(followerId: currentUserId, followingId: otherUserId)
                isFollowing = false
                followerCount -= 1
            } else {
                print("following user")
                try await SupabaseManager.shared.followUser(followerId: currentUserId, followingId: otherUserId)
                isFollowing = true
                followerCount += 1
            }
        } catch {
            print("error toggling follow: \(error.localizedDescription)")
            throw error
        }
    }
}
