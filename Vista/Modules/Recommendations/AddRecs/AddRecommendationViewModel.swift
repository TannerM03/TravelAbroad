//
//  AddRecommendationViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/3/25.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
class AddRecommendationViewModel {
    var isLoading = false
    var errorMessage: String?
    var placeName: String = ""
    var selectedImage: UIImage?
    var selectedImage2: UIImage?
    var selectedImage3: UIImage?
    var description = ""
    var isSubmitting = false
    var userRating: Double = 0.0
    var showNoRatingAlert = false

    // Properties from AddRecommendationView
    let cityId: String
    let cityName: String
    var selectedCategory: CategoryType
    var dismiss: (() -> Void)?

    private let supabaseManager = SupabaseManager.shared

    init(cityId: String, cityName: String, selectedCategory: CategoryType) {
        self.cityId = cityId
        self.cityName = cityName
        self.selectedCategory = selectedCategory
    }

    func submitRecommendation() {
        // Check if user has entered a place name
        guard !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("AddRecommendation: No place name entered")
            return
        }

        // Check if user has selected a rating
        guard userRating > 0 else {
            print("AddRecommendation: No rating selected")
            showNoRatingAlert = true
            return
        }

        isSubmitting = true

        Task {
            do {
                var imageUrl: String?
                var imageUrl2: String?
                var imageUrl3: String?

                // Upload images if user selected them
                if let image = selectedImage {
                    imageUrl = try await supabaseManager.uploadRecommendationImage(image)
                }

                if let image2 = selectedImage2 {
                    imageUrl2 = try await supabaseManager.uploadCommentImage(image2)
                }

                if let image3 = selectedImage3 {
                    imageUrl3 = try await supabaseManager.uploadCommentImage(image3)
                }

                let recommendation = try await SupabaseManager.shared.createRecommendation(
                    cityId: cityId,
                    name: placeName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: nil,
                    category: selectedCategory,
                    location: nil,
                    imageUrl: imageUrl,
                )

                // Add the user's rating and comment to the newly created recommendation
                _ = try await supabaseManager.submitComment(
                    recommendationId: recommendation.id,
                    text: description.isEmpty ? nil : description,
                    imageUrl: imageUrl,
                    imageUrl2: imageUrl2,
                    imageUrl3: imageUrl3,
                    rating: userRating
                )

                isSubmitting = false
                print("AddRecommendation: Successfully created recommendation with ID: \(recommendation.id) and added rating")
                dismiss?()
            } catch {
                isSubmitting = false
                print("AddRecommendation: Error creating recommendation: \(error.localizedDescription)")
            }
        }
    }
}
