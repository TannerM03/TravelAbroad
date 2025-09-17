//
//  CommentsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/10/25.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
class CommentsViewModel {
    var comments: [Comment] = []
    var isLoading = false
    var userRating: Double?
    var recommendation: Recommendation?
    var isGeneratingSummary: Bool = false
    var sortOption: CommentSortOption = .recent

    private let supabaseManager = SupabaseManager.shared

    var displayedAverageRating: Double {
        guard !comments.isEmpty else { return recommendation?.avgRating ?? 0.0 }
        let total = comments.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(comments.count)
    }

    func fetchComments(for recommendationId: String) async {
        isLoading = true

        do {
            comments = try await supabaseManager.fetchCommentsWithVotes(for: recommendationId, sortBy: sortOption)
        } catch {
            print("Error fetching comments: \(error)")
            // Fallback to original method if one above fails (from before i had voting)
            do {
                comments = try await supabaseManager.fetchComments(for: recommendationId)
                applySorting()
            } catch {
                print("Error with fallback fetch: \(error)")
            }
        }

        isLoading = false
    }

    private func applySorting() {
        switch sortOption {
        case .upvotes:
            comments.sort { $0.netVotes > $1.netVotes }
        case .recent:
            comments.sort { $0.createdAt > $1.createdAt }
        case .downvotes:
            comments.sort { $0.netVotes < $1.netVotes }
        }
    }

    func submitComment(recommendationId: String, text: String?, image: UIImage?, rating: Int) async {
        do {
            var imageUrl: String?

            if let image = image {
                imageUrl = try await supabaseManager.uploadCommentImage(image)
            }

            let newComment = try await supabaseManager.submitComment(
                recommendationId: recommendationId,
                text: text,
                imageUrl: imageUrl,
                rating: rating
            )

            comments.insert(newComment, at: 0)
        } catch {
            print("Error submitting comment: \(error)")
        }
    }

    func generateSummary(for recommendation: Recommendation, comments: [Comment]) async {
        isGeneratingSummary = true

        do {
            let summary = try await ConfigManager.shared.summaryService.generateSummary(for: comments, recommendationName: recommendation.name)

            var updatedRecommendation = recommendation
            updatedRecommendation.aiSummary = summary
            self.recommendation = updatedRecommendation

            try await SupabaseManager.shared.saveSummaryToDatabase(recommendationId: recommendation.id, summary: summary)

        } catch {
            print("Failed to generate summary: \(error)")
        }
        isGeneratingSummary = false
    }

    func fetchUserRating(for recommendationId: String) async {
        do {
            userRating = try await supabaseManager.getUserRecommendationRating(recommendationId: recommendationId)
        } catch {
            print("Error fetching user rating: \(error)")
        }
    }

    func submitRating(for recommendationId: String, rating: Int) async {
        do {
            try await supabaseManager.submitRecommendationRating(recommendationId: recommendationId, rating: rating)
            userRating = Double(rating)
        } catch {
            print("Error submitting rating: \(error)")
        }
    }

    func refreshRecommendationData() async {
        guard let recId = recommendation?.id else { return }
        do {
            // Fetch updated recommendation data from database
            let updatedRecs = try await supabaseManager.fetchRecommendations(cityId: UUID(uuidString: recommendation?.cityId ?? "") ?? UUID())
            if let updatedRec = updatedRecs.first(where: { $0.id == recId }) {
                recommendation = updatedRec
            }
        } catch {
            print("Error refreshing recommendation data: \(error)")
        }
    }

    func toggleVote(commentId: String, voteType: VoteType) async {
        guard let commentIndex = comments.firstIndex(where: { $0.id == commentId }) else { return }
        var comment = comments[commentIndex]

        do {
            if comment.userVote == voteType {
                // Remove vote if same type clicked
                try await supabaseManager.removeVoteFromComment(commentId: commentId)
                comment.userVote = nil

                // Update local counts
                if voteType == .upvote {
                    comment.upvoteCount = max(0, comment.upvoteCount - 1)
                } else {
                    comment.downvoteCount = max(0, comment.downvoteCount - 1)
                }
            } else {
                // Add/change vote
                try await supabaseManager.voteOnComment(commentId: commentId, voteType: voteType)

                // Remove previous vote if exists
                if let previousVote = comment.userVote {
                    if previousVote == .upvote {
                        comment.upvoteCount = max(0, comment.upvoteCount - 1)
                    } else {
                        comment.downvoteCount = max(0, comment.downvoteCount - 1)
                    }
                }

                // Add new vote
                comment.userVote = voteType

                // Update local counts
                if voteType == .upvote {
                    comment.upvoteCount += 1
                } else {
                    comment.downvoteCount += 1
                }
            }

            // Update net votes
            comment.netVotes = comment.upvoteCount - comment.downvoteCount

            // Update the comment in array
            comments[commentIndex] = comment

            // Re-apply sorting
            applySorting()

        } catch {
            print("Error toggling vote: \(error)")
        }
    }

    func updateSortOption(_ newOption: CommentSortOption) {
        sortOption = newOption

        // Re-fetch comments with new sorting from backend
        if let recId = recommendation?.id {
            Task {
                await fetchComments(for: recId)
            }
        } else {
            // Fallback to local sorting if no recommendation ID
            applySorting()
        }
    }
}
