//
//  Comment.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/10/25.
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let userId: String
    let recommendationId: String
    let text: String
    let imageUrl: String?
    let createdAt: Date
    let userDisplayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recommendationId = "recommendation_id"
        case text
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case userDisplayName = "user_display_name"
    }
}