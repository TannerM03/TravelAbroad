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
    var searchQuery: String = ""

    // Pagination state
    var isLoadingMore = false
    var hasMoreUsers = true
    var currentPage = 0
    let pageSize = 30

    func fetchUser() async {
        do {
            let user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user.id
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func searchUsers(query: String) async {
        guard let userId = userId else { return }
        guard query.count >= 2 else {
            // Clear results if query is too short
            profiles = []
            return
        }

        isLoading = true
        currentPage = 0
        hasMoreUsers = true
        let userIdString = userId.uuidString

        do {
            profiles = try await SupabaseManager.shared.fetchUsers(
                userId: userIdString,
                searchQuery: query,
                limit: pageSize,
                offset: 0
            )
            if profiles.count < pageSize {
                hasMoreUsers = false
            }
        } catch {
            print("error searching profiles in vm: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func loadMoreUsers() async {
        guard let userId = userId else { return }
        guard !isLoadingMore, hasMoreUsers, searchQuery.count >= 2 else { return }

        isLoadingMore = true
        currentPage += 1
        let userIdString = userId.uuidString

        do {
            let newProfiles = try await SupabaseManager.shared.fetchUsers(
                userId: userIdString,
                searchQuery: searchQuery,
                limit: pageSize,
                offset: currentPage * pageSize
            )
            profiles.append(contentsOf: newProfiles)
            if newProfiles.count < pageSize {
                hasMoreUsers = false
            }
        } catch {
            print("error loading more profiles in vm: \(error.localizedDescription)")
            currentPage -= 1
        }
        isLoadingMore = false
    }
}
