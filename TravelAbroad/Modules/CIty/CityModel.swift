//
//  City.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for each city in database
struct City: Codable, Identifiable {
    let id: String
    let name: String
    let country: String
    let imageUrl: String?
    let avgRating: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case country
        case imageUrl = "image_url"
        case avgRating = "avg_rating"
    }
}

// model for cities with user's personal rating
struct UserRatedCity: Codable, Identifiable {
    let id: UUID
    let name: String
    let country: String
    let imageUrl: String?
    let userRating: Double?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case country
        case imageUrl
        case userRating
        case createdAt = "created_at"
    }
}
