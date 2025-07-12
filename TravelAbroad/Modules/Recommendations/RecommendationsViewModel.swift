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
    @Published var userId: UUID = UUID()
    @Published var user: User?
    @Published var cityRating: Double? = nil
    @Published var selectedCategory: CategoryType? = .activities
    @Published var isFavoriteCity: Bool = false
    
//    @Published var favoriteCities: [City] = []

//    func isFavorite(cityId: UUID) -> Bool {
//        print("returning isFavorite")
//        return favoriteCities.contains(where: { $0.id == cityId.uuidString })
//    }

    
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
    
//    func getUserCityRating(for cityId: UUID) async -> Double? {
//        do {
//            cityRating = try await SupabaseManager.shared.getCityRatingForUser(cityId: cityId, userId: userId)
//        } catch {
//            print("Failed to fetch city rating for user: \(error)")
//            cityRating = nil
//        }
//        return cityRating
//    }
    
    func getUserCityRating(for cityId: UUID) async {
        do {
            cityRating = try await SupabaseManager.shared.getCityRatingForUser(cityId: cityId, userId: userId)
        } catch {
            print("Failed to fetch city rating for user: \(error.localizedDescription)")
            cityRating = nil
        }
    }

    
    func isCityFavorite(cityId: UUID) async {
        do {
            isFavoriteCity = try await SupabaseManager.shared.getIsCityFavorite(cityId: cityId, userId: userId)
        } catch {
            print("couldn't determine is city is favorite (vm): \(error)")
        }
    }
    
//    func getFavorites(cityId: UUID) async{
//        do {
//            favoriteCities = try await SupabaseManager.shared.fetchUserBucketList(userId: userId)
//            print("fav cities vm: \(favoriteCities)")
//            isFavoriteCity = favoriteCities.contains(where: { $0.id == cityId.uuidString })
//        } catch {
//            print("failed to get bucket list: \(error)")
//        }
//    }
    
//    func checkIfCityIsFavorite(cityId: UUID) async {
//        do {
//            let bucketList = try await SupabaseManager.shared.fetchUserBucketList(userId: userId)
//            isFavorite = bucketList.contains { $0.id == cityId.uuidString }
//        } catch {
//            print("failed to check if city is favorite: \(error)")
//            isFavorite = false
//        }
//    }
    
    func addOrRemoveFavorite(cityId: UUID) async {
        do {
            if isFavoriteCity {
                isFavoriteCity = false
                try await SupabaseManager.shared.removeUserFavoriteCity(userId: userId, cityId: cityId)
            }
            else {
                isFavoriteCity = true
                try await SupabaseManager.shared.addUserFavoriteCity(userId: userId, cityId: cityId)
            }
        } catch {
            print("failed to add or remove from bucket list: \(error)")
        }
    }
}

