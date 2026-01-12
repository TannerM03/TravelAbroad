//
//  FeedItemModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 10/13/25
//

import Foundation

enum FeedItemType: String, Codable {
    case cityRating
    case spotReview
}

struct FeedItem: Codable, Identifiable {
    let id: String
    let type: FeedItemType
    let userId: String
    let username: String
    let userImageUrl: String?
    let rating: Double
    let createdAt: Date
    let isUserPopular: Bool

    // City rating specific fields
    let cityId: String?
    let cityName: String?
    let cityImageUrl: String?
    let cityCountry: String?

    // Spot review specific fields
    let spotId: String?
    let spotName: String?
    let spotImageUrl: String?
    let commentImageUrl: String? // User-uploaded comment image
    let spotCategory: CategoryType?
    let spotLocation: String?
    let spotDescription: String?
    let spotAvgRating: Double?
    let spotCityCountry: String?
    let reviewComment: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case userId = "user_id"
        case username
        case userImageUrl = "user_image_url"
        case rating
        case createdAt = "created_at"
        case isUserPopular = "is_popular"
        case cityId = "city_id"
        case cityName = "city_name"
        case cityImageUrl = "city_image_url"
        case cityCountry = "city_country"
        case spotId = "spot_id"
        case spotName = "spot_name"
        case spotImageUrl = "spot_image_url"
        case commentImageUrl = "comment_image_url"
        case spotCategory = "spot_category"
        case spotLocation = "spot_location"
        case spotDescription = "spot_description"
        case spotAvgRating = "spot_avg_rating"
        case spotCityCountry = "spot_city_country"
        case reviewComment = "review_comment"
    }

    // Convenience computed properties
    var displayName: String {
        switch type {
        case .cityRating:
            return cityName ?? "Unknown City"
        case .spotReview:
            return spotName ?? "Unknown Spot"
        }
    }

    var displayImageUrl: String? {
        switch type {
        case .cityRating:
            return cityImageUrl
        case .spotReview:
            return spotImageUrl
        }
    }

    var actionText: String {
        switch type {
        case .cityRating:
            return "rated"
        case .spotReview:
            return "reviewed"
        }
    }

    var locationText: String? {
        switch type {
        case .cityRating:
            return cityCountry
        case .spotReview:
            return cityName
        }
    }

    // Get country for flag display
    var countryForFlag: String? {
        switch type {
        case .cityRating:
            return cityCountry
        case .spotReview:
            return spotCityCountry
        }
    }

    // Convert to Recommendation for navigation (spot reviews only)
    func toRecommendation() -> Recommendation? {
        guard type == .spotReview,
              let spotId = spotId,
              let spotName = spotName,
              let spotCategory = spotCategory,
              let cityIdString = cityId,
              let spotAvgRating = spotAvgRating
        else {
            return nil
        }

        return Recommendation(
            id: spotId,
            userId: userId,
            cityId: cityIdString,
            category: spotCategory,
            name: spotName,
            description: spotDescription,
            imageUrl: spotImageUrl,
            location: spotLocation,
            avgRating: spotAvgRating,
            aiSummary: nil,
            summaryUpdatedAt: nil
        )
    }
}
