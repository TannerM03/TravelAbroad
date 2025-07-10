//
//  CommentsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/10/25.
//

import Foundation
import UIKit

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var userRating: Double? = nil
    
    private let supabaseManager = SupabaseManager.shared
    
    func fetchComments(for recommendationId: String) async {
        isLoading = true
        
        do {
            comments = try await supabaseManager.fetchComments(for: recommendationId)
        } catch {
            print("Error fetching comments: \(error)")
        }
        
        isLoading = false
    }
    
    func submitComment(recommendationId: String, text: String, image: UIImage?) async {
        do {
            var imageUrl: String? = nil
            
            if let image = image {
                imageUrl = try await supabaseManager.uploadCommentImage(image)
            }
            
            let newComment = try await supabaseManager.submitComment(
                recommendationId: recommendationId,
                text: text,
                imageUrl: imageUrl
            )
            
            comments.insert(newComment, at: 0)
        } catch {
            print("Error submitting comment: \(error)")
        }
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
}