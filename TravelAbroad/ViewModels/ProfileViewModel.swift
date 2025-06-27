//
//  ProfileViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/18/25.
//

import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var user: User?
    @Published var profileImageURL: String?
    @Published var userId: UUID? = nil

    func logOut() async throws {
        try await SupabaseManager.shared.supabase.auth.signOut()
    }
    
    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            email = user?.email ?? ""
            userId = user?.id
            
            if let userId = userId {
                username = try await SupabaseManager.shared.fetchUsername(userId: userId)
            }
            
            if let userId = userId {
                let fileName = "\(userId)/profile.jpg"
                profileImageURL = try? SupabaseManager.shared.supabase.storage
                    .from("profiles")
                    .getPublicURL(path: fileName)
                    .absoluteString
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
}
