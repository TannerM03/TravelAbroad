//
//  IteneraryItem.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

// model for a singular item in an itenerary, multiple of these will make up an itenerary
struct ItineraryItem: Codable, Identifiable {
    let id: String
    let iteneraryId: String
    let recId: String
    let day: Int
    let time: String
    let notes: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case iteneraryId = "itenerary_id"
        case recId = "rec_id"
        case day
        case time
        case notes
    }
}
