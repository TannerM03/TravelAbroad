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
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case country
        case imageUrl = "image_url"
    }
}
