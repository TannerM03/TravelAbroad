//
//  RecommendationsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class RecommendationsViewModel {
    var recommendations: [Recommendation] = []
    var isLoading = false
    var userId: UUID = .init()
    var user: User?
    var userRating: Double?
    var selectedCategory: CategoryType? = .all
    var isFavoriteCity: Bool = false
    var tempRating: Double?
    var userSearch: String = ""
    var isRatingOverlay = false
    var cityId: String = ""
    var cityName: String = ""
    var imageUrl: String = ""
    var isBucketList: Bool = false
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var avgRating: Double = 0.0
    var showSubmittedAlert: Bool = false

    var onRatingUpdated: ((Double) -> Void)?

    var categorizedRecs: [Recommendation] {
        if let selected = selectedCategory {
            if selected == CategoryType.all {
                return recommendations
            }
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
    
    func reloadAvgRating() async {
        guard let cityUUID = UUID(uuidString: cityId) else {
            print("Error: Invalid city ID")
            return
        }
        do {
            if let newAvgRating = try await SupabaseManager.shared.reloadAvgRating(cityId: cityUUID) {
                avgRating = newAvgRating
            }
        } catch {
            print("Error updating avg rating: \(error.localizedDescription)")
        }
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
            CityRatingManager.shared.updateRating(cityId: cityId.uuidString, rating: rating)
            onRatingUpdated?(userRating ?? 5.0)

            // Post notification for TravelHistoryViewModel to refresh
            NotificationCenter.default.post(name: NSNotification.Name("CityRatingAdded"), object: nil)
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
