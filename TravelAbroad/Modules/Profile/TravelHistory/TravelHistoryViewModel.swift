//
//  TravelHistoryViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/1/25.
//

import Foundation
import PhotosUI
import Supabase
import SwiftUI

@MainActor
class TravelHistoryViewModel: ObservableObject {
    @Published var cities: [UserRatedCity] = []
    @Published var isLoading = true
    @Published var userSearch = ""
    @Published var filter: CityFilter = .none
    @Published var user: User?
    @Published var userId: UUID? = nil

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
            print("Error getting cities in vm: \(error)")
        }
    }
}
