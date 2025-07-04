//
//  CityReview.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for an individual rating of a city overall
struct CityReviewModel: Encodable {
    let cityId: String
    let userId: String
    let rating: Double

    enum CodingKeys: String, CodingKey {
        case cityId = "city_id"
        case userId = "user_id"
        case rating = "overall_rating"
    }
}
