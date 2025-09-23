//
//  BucketListViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 7/1/25.
//

import Foundation
import Supabase

@MainActor
class BucketListViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var isLoading = true
    @Published var userSearch = ""
    @Published var filter: CityFilter = .none
    @Published var user: User?
    @Published var userId: UUID? = nil

    // what will be shown to the user, includes the text the user is searching for and searches for the city name and the country it's in
    var filteredCities: [City] {
        if userSearch.isEmpty {
            return cities
        } else {
            return cities.filter { city in
                city.name.lowercased().contains(userSearch.lowercased()) || city.country.lowercased().contains(userSearch.lowercased())
            }
        }
    }

    var sortedCities: [City] {
        if filter == .none {
            return filteredCities
        } else if filter == .best {
            return filteredCities.sorted { $0.avgRating ?? 0 > $1.avgRating ?? 0 }
        } else {
            return filteredCities.sorted { $0.avgRating ?? 0 < $1.avgRating ?? 0 }
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

    func getCities(userId _: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            print("in vm getCities bucketlist")
            let allCities = try await SupabaseManager.shared.fetchCities()
            cities = allCities.filter { $0.isBucketList }
            print("vm bucket list cities: \(cities)")
        } catch {
            print("Error getting cities in vm: \(error)")
        }
    }
}
