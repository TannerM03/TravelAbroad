//
//  OtherUserSpotsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/16/25.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class OtherUserSpotsViewModel {
    var spots: [ReviewedSpot] = []
    var isLoading = false
    var userId: UUID?
    var user: User?

    init(userId: String) {
        self.userId = UUID(uuidString: userId)
    }

    func getReviewedSpots(showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }

        do {
            if let userId = userId {
                spots = try await SupabaseManager.shared.fetchUserReviewedSpots(userId: userId)
            }
        } catch {
            print("Failed to fetch reviewed spots: \(error)")
        }

        if showLoading {
            isLoading = false
        }
    }
}
