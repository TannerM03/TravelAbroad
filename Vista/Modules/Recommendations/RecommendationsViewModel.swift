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
    var isLoadingMore = false
    var hasMoreRecs = true
    var currentPage = 0
    let pageSize = 50
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

        currentPage = 0
        hasMoreRecs = true

        do {
            // If searching, fetch all matching results (no pagination)
            if !userSearch.isEmpty {
                recommendations = try await SupabaseManager.shared.fetchRecommendations(
                    cityId: cityId,
                    category: selectedCategory,
                    searchQuery: userSearch,
                    limit: nil,
                    offset: 0
                )
                hasMoreRecs = false
            } else {
                // Normal pagination with category filter
                let fetchedRecs = try await SupabaseManager.shared.fetchRecommendations(
                    cityId: cityId,
                    category: selectedCategory,
                    searchQuery: nil,
                    limit: pageSize,
                    offset: 0
                )
                recommendations = fetchedRecs

                if fetchedRecs.count < pageSize {
                    hasMoreRecs = false
                }
            }
        } catch {
            print("Error getting recommendations in vm: \(error)")
        }
    }

    func loadMoreRecs(cityId: UUID) async {
        guard !isLoadingMore, hasMoreRecs, userSearch.isEmpty else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let fetchedRecs = try await SupabaseManager.shared.fetchRecommendations(
                cityId: cityId,
                category: selectedCategory,
                searchQuery: nil,
                limit: pageSize,
                offset: currentPage * pageSize
            )

            recommendations.append(contentsOf: fetchedRecs)

            if fetchedRecs.count < pageSize {
                hasMoreRecs = false
            }
        } catch {
            print("Error loading more recommendations: \(error)")
            currentPage -= 1
        }

        isLoadingMore = false
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
