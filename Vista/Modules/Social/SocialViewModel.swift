//
//  SocialViewModel.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/17/25.
//

import Foundation
import Observation
import Supabase
import SwiftUI

@MainActor
@Observable
class SocialViewModel {
    var profiles: [OtherProfile] = []
    var userId: UUID?
    var user: User?
    var username: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var profileImageURL: String?
    var imageState: ImageState = .empty
    private var imageCache: [String: Image] = [:]

    func fetchUser() async {
        do {
            user = try await SupabaseManager.shared.supabase.auth.user()
            userId = user?.id

            if let userId = userId {
                let names = try await SupabaseManager.shared.fetchUsernameAndNames(userId: userId)
                username = names[0]
                firstName = names[1]
                lastName = names[2]
                profileImageURL = try await SupabaseManager.shared.fetchProfilePic(userId: userId)

                if let urlString = profileImageURL, let url = URL(string: urlString) {
                    await loadImageFromURL(url)
                }

            } else {
                print("userId didn't work yet")
            }

        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    private func loadImageFromURL(_ url: URL) async {
        let urlString = url.absoluteString

        // Check cache first
        if let cachedImage = imageCache[urlString] {
            imageState = .success(cachedImage)
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                imageCache[urlString] = image
                imageState = .success(image)
            }
        } catch {
            print("Failed to load image from URL: \(error)")
        }
    }

    func fetchProfiles(userId: UUID) async {
        let userIdString = userId.uuidString
        do {
            profiles = try await SupabaseManager.shared.fetchUsers(userId: userIdString)
        } catch {
            print("error fetching profiles in vm: \(error.localizedDescription)")
        }
    }
}
