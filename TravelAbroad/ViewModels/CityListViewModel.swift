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
    
    func getCities() async {
        isLoading = true
        defer { isLoading = false }
        do {
            cities = try await SupabaseManager.shared.fetchCities()
        } catch {
            print(error)
        }
    }
}
