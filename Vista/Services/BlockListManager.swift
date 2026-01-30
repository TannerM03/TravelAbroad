//
//  BlockListManager.swift
//  Vista
//
//  Manages blocked user list with in-memory caching for fast filtering
//

import Foundation
import Observation

@MainActor
@Observable
class BlockListManager {
    static let shared = BlockListManager()

    private(set) var blockedUserIds: Set<UUID> = []
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    private init() {
        // Private initializer for singleton
    }

    /// Loads blocked users from database and caches them
    func loadBlockedUsers() async {
        do {
            let blockedIds = try await SupabaseManager.shared.getBlockedUsers()
            blockedUserIds = Set(blockedIds)
            lastFetchTime = Date()
            print("✅ Loaded \(blockedIds.count) blocked users into cache")
        } catch {
            print("❌ Failed to load blocked users: \(error)")
        }
    }

    /// Refreshes cache if it's stale (older than cacheDuration)
    func refreshIfNeeded() async {
        if shouldRefresh() {
            await loadBlockedUsers()
        }
    }

    /// Checks if a user is blocked (uses cache)
    /// - Parameter userId: UUID of user to check
    /// - Returns: True if user is blocked
    func isUserBlocked(_ userId: UUID) -> Bool {
        return blockedUserIds.contains(userId)
    }

    /// Checks if a user is blocked (uses cache), string version
    /// - Parameter userId: UUID string of user to check
    /// - Returns: True if user is blocked
    func isUserBlocked(_ userId: String) -> Bool {
        guard let uuid = UUID(uuidString: userId) else { return false }
        return blockedUserIds.contains(uuid)
    }

    /// Blocks a user and updates cache immediately
    /// - Parameter userId: UUID of user to block
    func blockUser(_ userId: UUID) async throws {
        // Update database
        try await SupabaseManager.shared.blockUser(blockedUserId: userId)

        // Update cache immediately (optimistic UI)
        blockedUserIds.insert(userId)

        print("✅ Blocked user \(userId.uuidString) and updated cache")
    }

    /// Unblocks a user and updates cache immediately
    /// - Parameter userId: UUID of user to unblock
    func unblockUser(_ userId: UUID) async throws {
        // Update database
        try await SupabaseManager.shared.unblockUser(blockedUserId: userId)

        // Update cache immediately (optimistic UI)
        blockedUserIds.remove(userId)

        print("✅ Unblocked user \(userId.uuidString) and updated cache")
    }

    /// Gets list of blocked user IDs (for database queries)
    /// - Returns: Array of blocked user UUIDs
    func getBlockedUserIds() -> [UUID] {
        return Array(blockedUserIds)
    }

    /// Gets list of blocked user IDs as strings (for database queries)
    /// - Returns: Array of blocked user UUID strings
    func getBlockedUserIdStrings() -> [String] {
        return blockedUserIds.map { $0.uuidString }
    }

    /// Clears the cache (call on logout)
    func clearCache() {
        blockedUserIds.removeAll()
        lastFetchTime = nil
        print("✅ Cleared blocked users cache")
    }

    /// Forces a refresh from the database
    func forceRefresh() async {
        await loadBlockedUsers()
    }

    // MARK: - Private Helpers

    private func shouldRefresh() -> Bool {
        guard let lastFetch = lastFetchTime else {
            return true // Never fetched, should refresh
        }

        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch > cacheDuration
    }
}
