//
//  CommentsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/10/25.
//

import Foundation
import Observation
import Supabase
import UIKit

@MainActor
@Observable
class CommentsViewModel {
    var comments: [Comment] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMoreComments = true
    var currentPage = 0
    let pageSize = 20
    var userRating: Double?
    var recommendation: Recommendation?
    var isGeneratingSummary: Bool = false
    var sortOption: CommentSortOption = .recent
    var userId: UUID?
    var user: User?
    private let supabaseManager = SupabaseManager.shared

    var displayedAverageRating: Double {
        guard !comments.isEmpty else { return recommendation?.avgRating ?? 0.0 }
        let total = comments.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(comments.count)
    }

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id
        } catch {
            print("error fetching user in comments view mode: \(error.localizedDescription)")
        }
    }

    func fetchComments(for recommendationId: String) async {
        isLoading = true
        currentPage = 0
        hasMoreComments = true

        do {
            let fetchedComments = try await supabaseManager.fetchCommentsWithVotes(
                for: recommendationId,
                sortBy: sortOption,
                limit: pageSize,
                offset: 0
            )
            comments = fetchedComments

            // If we got less than pageSize, there are no more comments
            if fetchedComments.count < pageSize {
                hasMoreComments = false
            }
        } catch {
            print("Error fetching comments: \(error)")
            // Fallback to original method if one above fails (from before i had voting)
            do {
                comments = try await supabaseManager.fetchComments(for: recommendationId)
                applySorting()
                hasMoreComments = false // Fallback doesn't support pagination
            } catch {
                print("Error with fallback fetch: \(error)")
            }
        }

        isLoading = false
    }

    func loadMoreComments(for recommendationId: String) async {
        guard !isLoadingMore, hasMoreComments else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let fetchedComments = try await supabaseManager.fetchCommentsWithVotes(
                for: recommendationId,
                sortBy: sortOption,
                limit: pageSize,
                offset: currentPage * pageSize
            )

            comments.append(contentsOf: fetchedComments)

            // If we got less than pageSize, there are no more comments
            if fetchedComments.count < pageSize {
                hasMoreComments = false
            }
        } catch {
            print("Error loading more comments: \(error)")
            currentPage -= 1 // Revert page increment on error
        }

        isLoadingMore = false
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

    func submitComment(recommendationId: String, text: String?, image: UIImage?, image2: UIImage?, image3: UIImage?, rating: Double) async throws {
        do {
            var imageUrl: String?
            var imageUrl2: String?
            var imageUrl3: String?

            if let image = image {
                imageUrl = try await supabaseManager.uploadCommentImage(image)
                print("DEBUG: Uploaded image 1: \(imageUrl ?? "nil")")
            }

            if let image2 = image2 {
                imageUrl2 = try await supabaseManager.uploadCommentImage(image2)
                print("DEBUG: Uploaded image 2: \(imageUrl2 ?? "nil")")
            }

            if let image3 = image3 {
                imageUrl3 = try await supabaseManager.uploadCommentImage(image3)
                print("DEBUG: Uploaded image 3: \(imageUrl3 ?? "nil")")
            }

            print("DEBUG: Submitting comment with URLs - 1: \(imageUrl ?? "nil"), 2: \(imageUrl2 ?? "nil"), 3: \(imageUrl3 ?? "nil")")

            let newComment = try await supabaseManager.submitComment(
                recommendationId: recommendationId,
                text: text,
                imageUrl: imageUrl,
                imageUrl2: imageUrl2,
                imageUrl3: imageUrl3,
                rating: rating
            )

            print("DEBUG: Received comment back - imageUrl: \(newComment.imageUrl ?? "nil"), imageUrl2: \(newComment.imageUrl2 ?? "nil"), imageUrl3: \(newComment.imageUrl3 ?? "nil")")

            comments.insert(newComment, at: 0)
        } catch {
            print("Error submitting comment: \(error)")
            throw error
        }
    }

    func updateComment(commentId: String, recommendationId: String, text: String?, image: UIImage?, image2: UIImage?, image3: UIImage?, rating: Double, removeImage: Bool, removeImage2: Bool, removeImage3: Bool) async throws {
        do {
            var imageUrl: String?
            var imageUrl2: String?
            var imageUrl3: String?

            // Handle image 1
            if removeImage {
                imageUrl = ""
            } else if let image = image {
                imageUrl = try await supabaseManager.uploadCommentImage(image)
            }

            // Handle image 2
            if removeImage2 {
                imageUrl2 = ""
            } else if let image2 = image2 {
                imageUrl2 = try await supabaseManager.uploadCommentImage(image2)
            }

            // Handle image 3
            if removeImage3 {
                imageUrl3 = ""
            } else if let image3 = image3 {
                imageUrl3 = try await supabaseManager.uploadCommentImage(image3)
            }

            let updatedComment = try await supabaseManager.updateComment(
                commentId: UUID(uuidString: commentId)!,
                recommendationId: recommendationId,
                text: text,
                imageUrl: imageUrl,
                imageUrl2: imageUrl2,
                imageUrl3: imageUrl3,
                rating: rating,
                shouldUpdateImage: removeImage || image != nil,
                shouldUpdateImage2: removeImage2 || image2 != nil,
                shouldUpdateImage3: removeImage3 || image3 != nil
            )

            // Update the comment in the list
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index] = updatedComment
            }
        } catch {
            print("Error updating comment: \(error)")
            throw error
        }
    }

    func deleteSpotReview(reviewId: String, onSuccess: @escaping () -> Void) async {
        var didDelete = false
        do {
            if let userId = userId {
                didDelete = try await SupabaseManager.shared.deleteRecommendationIfNew(userId: userId, spotId: reviewId)
            }
            try await SupabaseManager.shared.deleteSpotComment(commentId: reviewId)
            await MainActor.run {
                comments.removeAll { $0.id == reviewId }
                if didDelete {
                    onSuccess()
                }
            }
        } catch {
            print("Could not delete spot because of error: \(error.localizedDescription)")
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

    func submitRating(for recommendationId: String, rating: Double) async {
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
            // Fetch updated recommendation data from database with all fields including summaryUpdatedAt
            let updatedRec = try await supabaseManager.fetchSingleRecommendation(recommendationId: recId)
            recommendation = updatedRec
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
