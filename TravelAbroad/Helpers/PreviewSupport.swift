////
////  PreviewSupport.swift
////  TravelAbroad
////
////  Created by Tanner Macpherson on 6/26/25.
////
//
// import Foundation
// import SwiftUI
//
//// MARK: - Mock ViewModels for Previews
//
// class MockCityListViewModel: ObservableObject {
//    @Published var cities: [City] = []
//    @Published var isLoading = false
//    @Published var userSearch = ""
//    @Published var filter: CityFilter = .none
//
//    var sortedCities: [City] {
//        let filtered = cities.filter { city in
//            userSearch.isEmpty || city.name.localizedCaseInsensitiveContains(userSearch) || city.country.localizedCaseInsensitiveContains(userSearch)
//        }
//
//        switch filter {
//        case .none:
//            return filtered
//        case .highestRated:
//            return filtered.sorted { $0.avgRating > $1.avgRating }
//        case .lowestRated:
//            return filtered.sorted { $0.avgRating < $1.avgRating }
//        case .alphabetical:
//            return filtered.sorted { $0.name < $1.name }
//        }
//    }
//
//    func getCities() async {
//        // Mock implementation - no network calls
//    }
// }
//
// class MockRecommendationsViewModel: ObservableObject {
//    @Published var recommendations: [Recommendation] = []
//    @Published var isLoading = false
//    @Published var filteredCategory: CategoryType?
//
//    var filteredRecommendations: [Recommendation] {
//        if let category = filteredCategory {
//            return recommendations.filter { $0.category == category }
//        }
//        return recommendations
//    }
//
//    func fetchRecommendations(cityId: String) async {
//        // Mock implementation - no network calls
//    }
// }
//
//// MARK: - Preview Helper Functions
//
// struct PreviewContainer<Content: View>: View {
//    let content: Content
//
//    init(@ViewBuilder content: () -> Content) {
//        self.content = content()
//    }
//
//    var body: some View {
//        content
//            .environment(\.colorScheme, .light)
//    }
// }
//
//// MARK: - Mock User for Profile Preview
//
// extension MockData {
//    static let mockUser = (
//        email: "john.doe@example.com",
//        username: "johndoe_traveler",
//        id: "mock-user-id"
//    )
// }
