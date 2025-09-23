//
//  RecommendationModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation
import SwiftUI

// model for a recommended location from a user's submission
struct Recommendation: Codable, Identifiable {
    let id: String
    let userId: String
    let cityId: String
    let category: CategoryType
    let name: String
    let description: String?
    let imageUrl: String?
    let location: String?
    let avgRating: Double
    var aiSummary: String?
    var summaryUpdatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cityId = "city_id"
        case category
        case name
        case description
        case imageUrl = "image_url"
        case location
        case avgRating = "avg_rating"
        case aiSummary = "ai_summary"
        case summaryUpdatedAt = "summary_updated_at"
    }

    // Memberwise initializer
    init(
        id: String,
        userId: String,
        cityId: String,
        category: CategoryType,
        name: String,
        description: String?,
        imageUrl: String?,
        location: String?,
        avgRating: Double,
        aiSummary: String? = nil,
        summaryUpdatedAt: Date? = nil,
    ) {
        self.id = id
        self.userId = userId
        self.cityId = cityId
        self.category = category
        self.name = name
        self.description = description
        self.imageUrl = imageUrl
        self.location = location
        self.avgRating = avgRating
        self.aiSummary = aiSummary
        self.summaryUpdatedAt = summaryUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        cityId = try container.decode(String.self, forKey: .cityId)
        category = try container.decode(CategoryType.self, forKey: .category)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        avgRating = try container.decode(Double.self, forKey: .avgRating)
        aiSummary = try container.decodeIfPresent(String.self, forKey: .aiSummary)

        // Handle date parsing from string
        if let dateString = try container.decodeIfPresent(String.self, forKey: .summaryUpdatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            summaryUpdatedAt = formatter.date(from: dateString) ?? {
                // Fallback for date-only format like "2025-07-21"
                let dateOnlyFormatter = DateFormatter()
                dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
                return dateOnlyFormatter.date(from: dateString)
            }()
        } else {
            summaryUpdatedAt = nil
        }
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case sights = "sight"
    case restaurants = "restaurant"
    case nightlife
    case activities = "activity"
    case hostels = "hostel"
    case other
}

extension CategoryType {
    var pillColor: Color {
        switch self {
        case .activities: return Color.green.opacity(0.4)
        case .nightlife: return Color.purple.opacity(0.4)
        case .restaurants: return Color.orange.opacity(0.4)
        case .hostels: return Color.blue.opacity(0.4)
        case .sights: return Color.pink.opacity(0.4)
        case .other: return Color.gray.opacity(0.4)
        }
    }
}
