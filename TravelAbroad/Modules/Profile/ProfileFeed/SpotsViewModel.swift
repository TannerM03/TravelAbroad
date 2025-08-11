//
//  SpotsViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 8/10/25.
//

import Foundation
import Supabase

@MainActor
class SpotsViewModel: ObservableObject {
    @Published var spots: [ReviewedSpot] = []
    @Published var isLoading = false
    @Published var userId: UUID?
    @Published var user: User?
    
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
}