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

    var categorizedRecs: [Recommendation] {
        if let selected = selectedCategory {
            return recommendations.filter { $0.category == selected }
        } else {
            return recommendations
        }
    }

    var filteredRecs: [Recommendation] {
        return categorizedRecs.sorted { $0.avgRating > $1.avgRating }
    }

    func initialize(rating: Double) {
        userRating = rating
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

    func updateCityReview(userId: UUID, cityId: UUID, rating: Double) async {
        do {
            userRating = tempRating
            try await SupabaseManager.shared.addCityReview(userId: userId, cityId: cityId, rating: rating)
        } catch {
            print("Error updating/creating city review in vm: \(error)")
        }
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
