//
//  Recommendation.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for a recommended location from a user's submission
struct Recommendation: Codable, Identifiable {
    let id: String
    let cityId: String
    let category: String
    let name: String
    let description: String
    let imageUrl: String
    let location: String
    let rating: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case cityId = "city_id"
        case category
        case name
        case description
        case imageUrl = "image_url"
        case location
        case rating
    }
}
