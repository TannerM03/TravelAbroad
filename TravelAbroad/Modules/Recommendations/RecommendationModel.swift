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
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case activities = "activity"
    case nightlife
    case restaurants = "restaurant"
    case hostels = "hostel"
    case sights = "sight"
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
