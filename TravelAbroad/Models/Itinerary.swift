//
//  Itinerary.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for an step by step itenerary for a specific city
struct Itinerary: Codable, Identifiable {
    let id: String
    let userId: String
    let cityId: String
    let title: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cityId = "city_id"
        case title
        case description
    }
}
