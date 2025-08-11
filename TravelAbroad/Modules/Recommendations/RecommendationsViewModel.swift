//
//  RecommendationsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Foundation
import Supabase

@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false
    @Published var userId: UUID = .init()
    @Published var user: User?
    @Published var userRating: Double? = nil
    @Published var selectedCategory: CategoryType? = .activities
    @Published var isFavoriteCity: Bool = false
    @Published var tempRating: Double? = nil
    @Published var userSearch: String = ""
    @Published var isRatingOverlay = false
    @Published var cityId: String = ""
    @Published var cityName: String = ""
    @Published var imageUrl: String = ""
    @Published var isBucketList: Bool = false
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var avgRating: Double = 0.0
    @Published var showSubmittedAlert: Bool = false

    var onRatingUpdated: ((Double) -> Void)?

    var categorizedRecs: [Recommendation] {
        if let selected = selectedCategory {
            return recommendations.filter { $0.category == selected }
        } else {
            return recommendations
        }
    }

    var searchedRecs: [Recommendation] {
        if userSearch.isEmpty {
            return categorizedRecs
        } else {
            return categorizedRecs.filter { rec in
                rec.name.lowercased().contains(userSearch.lowercased())
            }
        }
    }

    var filteredRecs: [Recommendation] {
        return categorizedRecs.sorted { $0.avgRating > $1.avgRating }
    }

    func initialize(rating: Double) {
        userRating = rating
    }

    func initializeCity(cityId: String, cityName: String, imageUrl: String, userRating: Double?, avgRating: Double, isBucketList: Bool, onRatingUpdated: ((Double) -> Void)?) {
        self.cityId = cityId
        self.cityName = cityName
        self.imageUrl = imageUrl
        self.userRating = userRating
        self.avgRating = avgRating
//        tempRating = userRating
        self.isBucketList = isBucketList
        isFavoriteCity = isBucketList
        self.onRatingUpdated = onRatingUpdated
    }

    func getRecs(cityId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            recommendations = try await SupabaseManager.shared.fetchRecommendations(cityId: cityId)
        } catch {
            print("Error getting cities in vm: \(error)")
        }
    }

    func getCoordinates(cityId: UUID) async {
        var coordinates: (Double, Double) = (0, 0)
        do {
            coordinates = try await SupabaseManager.shared.fetchCityCoordinates(cityId: cityId)
        } catch {
            print("Error fetching coordinates: \(error)")
        }
        latitude = coordinates.0
        longitude = coordinates.1
    }

    func updateCityReview(userId: UUID, cityId: UUID, rating: Double) async {
        do {
            userRating = tempRating
            try await SupabaseManager.shared.addCityReview(userId: userId, cityId: cityId, rating: rating)
            onRatingUpdated?(userRating ?? 5.0)
        } catch {
            print("Error updating/creating city review in vm: \(error)")
        }
    }

    func showRatingOverlay() {
        isRatingOverlay = true
    }

    func hideRatingOverlay() {
        isRatingOverlay = false
    }

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id ?? UUID()

        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func isCityFavorite(cityId: UUID) async {
        do {
            isFavoriteCity = try await SupabaseManager.shared.getIsCityFavorite(cityId: cityId, userId: userId)
        } catch {
            print("couldn't determine is city is favorite (vm): \(error)")
        }
    }

    func addOrRemoveFavorite(cityId: UUID) async {
        do {
            if isFavoriteCity {
                isFavoriteCity = false
                try await SupabaseManager.shared.removeUserFavoriteCity(userId: userId, cityId: cityId)
            } else {
                isFavoriteCity = true
                try await SupabaseManager.shared.addUserFavoriteCity(userId: userId, cityId: cityId)
            }
        } catch {
            print("failed to add or remove from bucket list: \(error)")
        }
    }
}
