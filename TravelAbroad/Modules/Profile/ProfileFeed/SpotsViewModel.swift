//
//  SpotsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/10/25.
//

import Foundation
import Supabase
import Observation

@MainActor
@Observable
class SpotsViewModel {
    var spots: [ReviewedSpot] = []
    var isLoading = false
    var userId: UUID?
    var user: User?

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func getReviewedSpots(userId: UUID, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        do {
            spots = try await SupabaseManager.shared.fetchUserReviewedSpots(userId: userId)
        } catch {
            print("Failed to fetch reviewed spots: \(error)")
        }

        if showLoading {
            isLoading = false
        }
    }
    
    func deleteSpot(spot: ReviewedSpot) async {
        do {
            if let userId = userId {
                try await SupabaseManager.shared.deleteSpotComment(userId: userId, spotId: UUID(uuidString: spot.recommendation.id)!)
            }
            spots.removeAll { $0.recommendation.id == spot.recommendation.id }
        } catch {
            print("Could not delete spot because of error: \(error.localizedDescription)")
        }
    }
}
