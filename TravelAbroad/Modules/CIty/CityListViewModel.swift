//
//  CityListViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/2/25.
//

import Foundation

@MainActor
class CityListViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var isLoading = false
    @Published var userSearch = ""
    @Published var filter: CityFilter = .best

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

    func getCities() async {
        isLoading = true
        defer { isLoading = false }
        do {
            cities = try await SupabaseManager.shared.fetchCities()
        } catch {
            print("Error getting cities in vm: \(error)")
        }
    }

    func updateCityRating(cityId: String, newRating: Double) {
        if let index = cities.firstIndex(where: { $0.id == cityId }) {
            cities[index].userRating = newRating
        }
    }
}
