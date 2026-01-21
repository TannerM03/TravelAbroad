//
//  OtherUserSpotsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/16/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class OtherUserSpotsViewModel {
    var spots: [ReviewedSpot] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMoreSpots = true
    var currentPage = 0
    let pageSize = 20
    var userId: UUID?
    var user: User?

    init(userId: String) {
        self.userId = UUID(uuidString: userId)
    }

    func getReviewedSpots(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        currentPage = 0
        hasMoreSpots = true

        do {
            if let userId = userId {
                let fetchedSpots = try await SupabaseManager.shared.fetchUserReviewedSpotsWithVotes(
                    userId: userId,
                    limit: pageSize,
                    offset: 0
                )
                spots = fetchedSpots

                // If we got less than pageSize, there are no more spots
                if fetchedSpots.count < pageSize {
                    hasMoreSpots = false
                }
            }
        } catch {
            print("Failed to fetch reviewed spots with votes: \(error)")
            do {
                if let userId = userId {
                    spots = try await SupabaseManager.shared.fetchUserReviewedSpots(userId: userId)
                    hasMoreSpots = false // Fallback doesn't support pagination
                }
            } catch {
                print("Failed to fetch reviewed spots: \(error)")
            }
        }

        if showLoading {
            isLoading = false
        }
    }

    func loadMoreSpots() async {
        guard !isLoadingMore, hasMoreSpots, let userId = userId else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let fetchedSpots = try await SupabaseManager.shared.fetchUserReviewedSpotsWithVotes(
                userId: userId,
                limit: pageSize,
                offset: currentPage * pageSize
            )

            spots.append(contentsOf: fetchedSpots)

            // If we got less than pageSize, there are no more spots
            if fetchedSpots.count < pageSize {
                hasMoreSpots = false
            }
        } catch {
            print("Error loading more spots: \(error)")
            currentPage -= 1 // Revert page increment on error
        }

        isLoadingMore = false
    }

    func toggleVote(spotId: String, voteType: VoteType) async {
        guard let spotIndex = spots.firstIndex(where: { $0.id == spotId }) else { return }
        var spot = spots[spotIndex]

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

            spots[spotIndex] = spot

        } catch {
            print("Error toggling vote: \(error)")
        }
    }
}
