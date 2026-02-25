//
//  CityListViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class CityListViewModel {
    var cities: [City] = []
    var countryOrder: [String: Int] = [:]
    var isLoading = false
    var userSearch = ""
    var filter: CityFilter = .best

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

    func sortedCountryKeys(from groupedCities: [String: [City]]) -> [String] {
        groupedCities.keys.sorted { a, b in
            let orderA = countryOrder[a] ?? 999
            let orderB = countryOrder[b] ?? 999
            if orderA != orderB { return orderA < orderB }
            return a < b
        }
    }

    func getCities() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let citiesResult = SupabaseManager.shared.fetchCities()
            async let orderResult = SupabaseManager.shared.fetchCountryOrder()
            cities = try await citiesResult
            countryOrder = (try? await orderResult) ?? [:]
        } catch {
            print("Error getting cities in vm: \(error)")
        }
    }

    func updateCityRating(cityId: String, newRating: Double) {
        if let index = cities.firstIndex(where: { $0.id == cityId }) {
            cities[index].userRating = newRating
        }
    }

    func submitCityRequest(city: String, country: String) async {
        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            let userId = user.id
            try await SupabaseManager.shared.requestCity(userId: userId, cityName: city, country: country)
        } catch {
            print("failed to submit city request citylistvm: \(error.localizedDescription)")
        }
    }
}
