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


    func getRecs(cityId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            recommendations = try await SupabaseManager.shared.fetchRecommendations(cityId: cityId)
        } catch {
            print("Error getting cities in vm: \(error)")
        }
    }
    
    func updateCityReview(userId: UUID, cityId: UUID, rating: Int) async {
        do {
            try await SupabaseManager.shared.addCityReview(userId: userId, cityId: cityId, rating: rating)
            print("vm userId: \(userId)")
            print("vm cityId: \(cityId)")
            print("vm rating: \(rating)")
        } catch {
            print("Error updating/creating city review in vm: \(error)")
        }
    }
    
    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id ?? UUID()
            print("recs user fetched")
            
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
}
