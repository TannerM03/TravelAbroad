//
//  TravelHistoryViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/1/25.
//

import Foundation
import Observation
import PhotosUI
import Supabase
import SwiftUI

@MainActor
@Observable
class TravelHistoryViewModel {
    var cities: [UserRatedCity] = []
    var isLoading = true
    var userSearch = ""
    var filter: CityFilter = .none
    var user: User?
    var userId: UUID?

    // what will be shown to the user, includes the text the user is searching for and searches for the city name and the country it's in
    var filteredCities: [UserRatedCity] {
        if userSearch.isEmpty {
            return cities
        } else {
            return cities.filter { city in
                city.name.lowercased().contains(userSearch.lowercased()) || city.country.lowercased().contains(userSearch.lowercased())
            }
        }
    }

    var sortedCities: [UserRatedCity] {
        if filter == .none {
            // Sort by newest created_at date first
            return filteredCities.sorted {
                guard let date1 = $0.createdAt, let date2 = $1.createdAt else { return false }
                return date1 > date2
            }
        } else if filter == .best {
            return filteredCities.sorted { $0.userRating ?? 0 > $1.userRating ?? 0 }
        } else {
            return filteredCities.sorted { $0.userRating ?? 0 < $1.userRating ?? 0 }
        }
    }

    var displayedCities: [UserRatedCity] {
        return sortedCities.map { city in
            var updatedCity = city
            if let newRating = CityRatingManager.shared.getRating(cityId: city.id.uuidString) {
                updatedCity.userRating = newRating
            }
            return updatedCity
        }
    }

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id

        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func getCities(userId: UUID, showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        defer {
            if showLoading {
                isLoading = false
            }
        }
        do {
            cities = try await SupabaseManager.shared.fetchUserTravelHistory(userId: userId)
        } catch {
            isLoading = false
            print("Error getting cities in vm: \(error)")
        }
        isLoading = false
    }

    func updateCityRating(cityId: String, newRating: Double) {
        if let index = cities.firstIndex(where: { $0.id.uuidString == cityId }) {
            cities[index].userRating = newRating
        }
    }

    func deleteCityRating(cityId: UUID) async {
        do {
            guard let userId = userId else { return }
            try await SupabaseManager.shared.deleteCityReview(userId: userId, cityId: cityId)
            // Remove from local array
            cities.removeAll { $0.id == cityId }

            // Clear from rating manager
            CityRatingManager.shared.clearRating(cityId: cityId.uuidString)
        } catch {
            print("Error deleting city rating: \(error)")
        }
    }
}
