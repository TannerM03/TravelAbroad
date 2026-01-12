//
//  OtherProfileModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/17/25.
//

import Foundation

struct OtherProfile: Codable, Identifiable {
    let id: UUID
    let username: String?
    let imageUrl: String?
    let isPopular: Bool
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case imageUrl = "image_url"
        case isPopular = "is_popular"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
