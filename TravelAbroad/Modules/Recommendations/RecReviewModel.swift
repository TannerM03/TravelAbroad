//
//  RecReview.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for review of a recommendation, these are how the recommendations are calculated and this will be displayed when the user clicks on a recommended location
struct RecReview: Codable, Identifiable {
    let id: String
    let userId: String
    let recId: String
    let rating: Int
    let comment: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recId = "rec_id"
        case rating
        case comment
    }
}
