//
//  PopularCreatorViewModel.swift
//  Vista
//
//  Logic for checking Popular Creator eligibility
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
class PopularCreatorViewModel {
    var accountCreatedDate: Date?
    var isLoading = false
    var errorMessage: String?

    // Requirements
    let requiredFollowers = 50
    let requiredSpotsRated = 25
    let requiredDaysActive = 30

    func fetchAccountCreationDate(userId _: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            accountCreatedDate = user.createdAt
        } catch {
            print("❌ Error fetching account creation date: \(error)")
            errorMessage = "Could not load account information"
        }

        isLoading = false
    }

    func daysActive() -> Int {
        guard let createdDate = accountCreatedDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: createdDate, to: Date())
        return components.day ?? 0
    }

    func meetsFollowerRequirement(currentFollowers: Int) -> Bool {
        return currentFollowers >= requiredFollowers
    }

    func meetsSpotsRatedRequirement(currentSpotsRated: Int) -> Bool {
        return currentSpotsRated >= requiredSpotsRated
    }

    func meetsDaysActiveRequirement() -> Bool {
        return daysActive() >= requiredDaysActive
    }

    func meetsAllRequirements(followers: Int, spotsRated: Int) -> Bool {
        return meetsFollowerRequirement(currentFollowers: followers) &&
            meetsSpotsRatedRequirement(currentSpotsRated: spotsRated) &&
            meetsDaysActiveRequirement()
    }
}
