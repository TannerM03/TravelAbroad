//
//  OtherUserTravelHistoryViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/16/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class OtherUserTravelHistoryViewModel {
    var cities: [UserRatedCity] = []
    var isLoading = true
    var userSearch = ""
    var filter: CityFilter = .none
    var user: User?
    var userId: UUID?

    init(userId: String) {
        self.userId = UUID(uuidString: userId)
    }

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
}
