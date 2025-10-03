//
//  CityRatingManager.swift
//  Vista
//
//  Created by Tanner Macpherson on 10/1/25.
//

import Foundation

@MainActor
@Observable
class CityRatingManager {
    static let shared = CityRatingManager()
    private var cityRatings: [String: Double] = [:]

    private init() {}

    func updateRating(cityId: String, rating: Double) {
        cityRatings[cityId] = rating
    }

    func getRating(cityId: String) -> Double? {
        return cityRatings[cityId]
    }

    func clearRating(cityId: String) {
        cityRatings.removeValue(forKey: cityId)
    }
}
