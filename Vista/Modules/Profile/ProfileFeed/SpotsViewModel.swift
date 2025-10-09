//
//  SpotsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/10/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class SpotsViewModel {
    var reviews: [ReviewedSpot] = []
    var isLoading = false
    var userId: UUID?
    var user: User?

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func getReviewedSpots(userId: UUID, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        do {
            reviews = try await SupabaseManager.shared.fetchUserReviewedSpotsWithVotes(userId: userId)
        } catch {
            print("Failed to fetch reviewed spots with votes: \(error)")
            do {
                reviews = try await SupabaseManager.shared.fetchUserReviewedSpots(userId: userId)
            } catch {
                print("Failed to fetch reviewed spots: \(error)")
            }
        }

        if showLoading {
            isLoading = false
        }
    }

    func deleteSpot(spot: ReviewedSpot) async {
        do {
            if let userId = userId {
                try await SupabaseManager.shared.deleteRecommendationIfNew(userId: userId, spotId: spot.id)
            }
            try await SupabaseManager.shared.deleteSpotComment(commentId: spot.id)
            reviews.removeAll { $0.id == spot.id }

        } catch {
            print("Could not delete spot because of error: \(error.localizedDescription)")
        }
    }

    func toggleVote(spotId: String, voteType: VoteType) async {
        guard let spotIndex = reviews.firstIndex(where: { $0.id == spotId }) else { return }
        var spot = reviews[spotIndex]

        do {
            if spot.userVote == voteType {
                try await SupabaseManager.shared.removeVoteFromComment(commentId: spotId)
                spot.userVote = nil

                if voteType == .upvote {
                    spot.upvoteCount = max(0, spot.upvoteCount - 1)
                } else {
                    spot.downvoteCount = max(0, spot.downvoteCount - 1)
                }
            } else {
                try await SupabaseManager.shared.voteOnComment(commentId: spotId, voteType: voteType)

                if let previousVote = spot.userVote {
                    if previousVote == .upvote {
                        spot.upvoteCount = max(0, spot.upvoteCount - 1)
                    } else {
                        spot.downvoteCount = max(0, spot.downvoteCount - 1)
                    }
                }

                spot.userVote = voteType

                if voteType == .upvote {
                    spot.upvoteCount += 1
                } else {
                    spot.downvoteCount += 1
                }
            }

            spot.netVotes = spot.upvoteCount - spot.downvoteCount

            reviews[spotIndex] = spot

        } catch {
            print("Error toggling vote: \(error)")
        }
    }
}
