//
//  RecReview.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for review of a recommendation, these are how the recommendations are calculated and this will be displayed when the user clicks on a recommended location
struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let recId: String
    let rating: Int
    let comment: String?
    let createdAt: Date
    let imageUrl: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recId = "rec_id"
        case rating
        case comment
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case username
    }
}

// Temporary struct for decoding the joined data
struct RatingTemporary: Codable {
    let id: String
    let userId: String
    let recommendationId: String
    let rating: Int
    let comment: String?
    let createdAt: Date
    let imageUrl: String?
    let profiles: TempProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recommendationId = "rec_id"
        case comment
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case profiles
        case rating
    }
}

struct TempProfile: Codable {
    let username: String
}
