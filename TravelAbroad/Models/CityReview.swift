//
//  CityReview.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for an individual rating of a city overall
struct CityReview: Codable, Identifiable {
    let id: String
    let userId: String
    let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case rating = "overall_rating"
    }
}
