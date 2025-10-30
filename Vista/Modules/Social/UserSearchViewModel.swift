//
//  UserSearchViewModel.swift
//  Vista
//
//  Created by Tanner Macpherson on 10/13/25.
//

import Foundation
import Observation

@MainActor
@Observable
class UserSearchViewModel {
    var profiles: [OtherProfile] = []
    var userId: UUID?
    var isLoading: Bool = false

    func fetchUser() async {
        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user.id
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func fetchProfiles(userId: UUID) async {
        isLoading = true
        let userIdString = userId.uuidString
        do {
            profiles = try await SupabaseManager.shared.fetchUsers(userId: userIdString)
        } catch {
            print("error fetching profiles in vm: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
